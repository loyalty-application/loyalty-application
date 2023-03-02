# loyalty-application

## Submodules
This repo consist of the following microservices linked as submodules:
- `next-js-frontend` - Web Application built with Next.js that serves users
- `go-gin-backend` - REST API Server written in Gin to handle requests from users and applications
- `go-worker-node` - Backend Worker Service written in Go to process Kafka events
- `go-sftp-txn` - Backend Injesting Service written in Go to listen for new transaction files to read and push to the Kafka Broker

## Dependencies
This project has the follow dependencies:
- Submodules referenced 
- [Docker](https://docs.docker.com/engine/install/)
- Docker Compose

## Setup

### Cloning the project 
This project contains submodules, to ensure the submodules are clone properly as well, run the clone command with the `--recursive` flag:
```bash
git clone --recursive <repository-url>
```

Take note that after you've cloned the submodules recursively, they will be directly checked out to a commit rather than a branch.

If you wish to contribute to the project, please checkout to the desired branch before writing any code:
```bash
# for example, my go-gin-backend repostory will be checked out to the main branch's commit
cd go-gin-backend

# you can see clearly by using the command `git branch` which returns something like * (HEAD detached at HASH)
git branch 

# to attach the head to any branch, you can simply checkout back to the branch you desire i.e main/development
git checkout main
```

### Environment variables
You will need to rename the `example.env` file to `.env` and replace the environment variables with the ones you want to use.

Please take note that all submodules associate with this project will also have their own `example.env` files that need to be copied, renamed and modified.


## Running
To start this project, run the following docker compose commmand while in the root directory of this project:
```bash
docker compose up
```


