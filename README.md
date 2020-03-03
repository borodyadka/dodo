# DoDo

DoDo is a simple tool to run Docker containers in context of current project... and you probably don't need it.

This tool was growed up from shell one-liner: `docker run --rm -it -v "$(pwd):/app" -w "/app" -u "$(id -u):$(id -g)"`.

## Why?

Sometimes it's not safe to use some tools on your local machine, because it has some side effects, like running post-install scripts ([like NPM does](https://docs.npmjs.com/misc/scripts)) or steal your passwords ([like some packages in NPM does](https://www.bleepingcomputer.com/news/security/npm-pulls-malicious-package-that-stole-login-passwords/)). But you need to run this tools, so it's more safe to run this in Docker container.

## Installation

Just copy `dodo.sh` to your `$PATH` and make it executable.

## Usage

`dodo [<flags>...] <image> <command>`

* `<flags>`: flags passes directly to `docker run` command, see [docs](https://docs.docker.com/engine/reference/commandline/run/)
    * `-e --env`;
    * `-p --publish`;
    * `-v --volume`;
    * `-w --workdir`, default is `/home/dodo`, automatically maps via volumes;
    * `-u --user`, default is your current user and group: `$(id -u):$(id -g)`;
    * any other flags causes an error;
* `<image>`: can be specific image (e.g. `alpine` or `alpine:latest`), path to directory with Dockerfile (e.g. `./deploy/docker`, always should start with `./`) or path to specific Dockerfile (e.g. `./tests/Dockerfile.testing`);
* `<command>`: some command to run in container, e.g. `npm install`

## License

[MIT](LICENSE)
