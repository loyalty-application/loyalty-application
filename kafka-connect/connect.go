package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"net"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/joho/godotenv"
	"github.com/pkg/sftp"
	splitCsv "github.com/tolik505/split-csv"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"
)

func connect() (*sftp.Client, *ssh.Client) {
	// Get SFTP To Go URL from environment
	if os.Getenv("APP_ENV") != "release" {
		godotenv.Load(".env")
	}

	host := os.Getenv("SFTP_HOST")
	user := os.Getenv("SFTP_USERNAME")
	pass := os.Getenv("SFTP_PASSWORD")

	// Default SFTP port
	port := 22

	// hostKey := getHostKey(host)

	fmt.Fprintf(os.Stdout, "Connecting to %s ...\n", host)

	var auths []ssh.AuthMethod

	// Try to use $SSH_AUTH_SOCK which contains the path of the unix file socket that the sshd agent uses
	// for communication with other processes.
	if aconn, err := net.Dial("unix", os.Getenv("SSH_AUTH_SOCK")); err == nil {
		auths = append(auths, ssh.PublicKeysCallback(agent.NewClient(aconn).Signers))
	}

	// Use password authentication if provided
	if pass != "" {
		auths = append(auths, ssh.Password(pass))
	}

	// Initialize client configuration
	config := ssh.ClientConfig{
		User: user,
		Auth: auths,
		// Uncomment to ignore host key check
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		// HostKeyCallback: ssh.FixedHostKey(hostKey),
	}

	addr := fmt.Sprintf("%s:%d", host, port)

	// Connect to server
	conn, err := ssh.Dial("tcp", addr, &config)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connecto to [%s]: %v\n", addr, err)
		os.Exit(1)
	}

	// Create new SFTP client
	sc, err := sftp.NewClient(conn)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to start SFTP subsystem: %v\n", err)
		os.Exit(1)
	}

	return sc, conn
}

// Download file from sftp server
func downloadFile(sc *sftp.Client, remoteFile, localFile string) (err error) {

	fmt.Fprintf(os.Stdout, "Downloading [%s] to [%s] ...\n", remoteFile, localFile)
	// Note: SFTP To Go doesn't support O_RDWR mode
	srcFile, err := sc.OpenFile(remoteFile, (os.O_RDONLY))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to open remote file: %v\n", err)
		return
	}
	defer srcFile.Close()

	dstFile, err := os.Create(localFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to open local file: %v\n", err)
		return
	}
	defer dstFile.Close()

	bytes, err := io.Copy(dstFile, srcFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to download remote file: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintf(os.Stdout, "%d bytes copied\n", bytes)

	return
}

func SplitCsv(dir string, outdir string) {
	splitter := splitCsv.New()
	splitter.Separator = ","          // "," is by default
	splitter.FileChunkSize = 20000000 //in bytes (20MB)
	splitter.WithHeader = false
	result, _ := splitter.Split(dir, outdir)
	fmt.Println(result)
	// Output: [testdata/test_1.csv testdata/test_2.csv testdata/test_3.csv]
}

func main() {

	var date string = strings.Split(time.Now().String(), " ")[0]

	if len(os.Args) > 1 {
		date = os.Args[1]
	}

	//create waitgroup for all goroutines to run finish
	var wg sync.WaitGroup

	//add each goroutine to the wait group
	wg.Add(1)
	go func() {
		handleSpend(date)
		defer wg.Done()
	}()
	wg.Add(1)
	go func() {
		handleCsv(date)
		defer wg.Done()
	}()
	wg.Wait()

	os.Exit(0)
}

func handleSpend(date string) {
	sc, conn := connect()
	defer conn.Close()
	defer sc.Close()
	err := downloadFile(sc, "/spend/"+date+"/spend.csv", "./spend/"+date+"spend.csv")

	if err != nil {
		return
	}

	file, err := os.Open("./spend/" + date + "spend.csv")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	// Read the CSV file
	reader := csv.NewReader(file)

	// Create a new CSV writer
	newFile, err := os.Create("./spend/" + date + "processedspend.csv")
	if err != nil {
		panic(err)
	}
	defer newFile.Close()
	writer := csv.NewWriter(newFile)

	// Iterate over the CSV rows and skip the first row
	isFirstRow := true
	for {
		row, err := reader.Read()
		if err != nil {
			break
		}
		if isFirstRow {
			isFirstRow = false
			continue
		}
		if err := writer.Write(row); err != nil {
			panic(err)
		}
	}
	writer.Flush()

	// split file into smaller files for connectors to process
	SplitCsv("./spend/"+date+"processedspend.csv", "/data/unprocessed/")

	filename := "./spend/" + date + "processedspend.csv"

	err = os.Remove(filename)
	if err != nil {
		// Handle the error if the file couldn't be deleted
		fmt.Printf("Error deleting file: %v", err)
		return
	}

	// Print a message to confirm that the file was deleted
	fmt.Printf("File %s deleted successfully.", filename)

}

func handleCsv(date string) {
	sc, conn := connect()
	defer conn.Close()
	defer sc.Close()
	err := downloadFile(sc, "/users/"+date+"/users.csv", "./users/"+date+"users.csv")

	if err != nil {
		return
	}

	file, err := os.Open("./users/" + date + "users.csv")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	// Read the CSV file
	reader := csv.NewReader(file)

	// Create a new CSV writer
	newFile, err := os.Create("./users/" + date + "processedusers.csv")
	if err != nil {
		panic(err)
	}
	defer newFile.Close()
	writer := csv.NewWriter(newFile)

	// Iterate over the CSV rows and skip the first row
	isFirstRow := true
	for {
		row, err := reader.Read()
		if err != nil {
			break
		}
		if isFirstRow {
			isFirstRow = false
			continue
		}
		if err := writer.Write(row); err != nil {
			panic(err)
		}
	}
	writer.Flush()

	// split file into smaller files for connectors to process
	SplitCsv("./users/"+date+"processedusers.csv", "/data/unprocessed/")

	filename := "./users/" + date + "processedusers.csv"

	err = os.Remove(filename)
	if err != nil {
		// Handle the error if the file couldn't be deleted
		fmt.Printf("Error deleting file: %v", err)
		return
	}

	// Print a message to confirm that the file was deleted
	fmt.Printf("File %s deleted successfully.", filename)
}
