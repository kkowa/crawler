# kkowa/apps/crawler

Web crawler component for kkowa.

## 🧰 Tech Stack

- **Language** Go 1
- **Framework** None
- **Source Control** Git + GitLab
- **CI·CD** GitLab CI

## ⚙️ Getting Started

This section describes how to set your local environments up.

### 🏗️ Setup

Followings are **required**.

- [Docker](https://www.docker.com/)

  To configure other dependent services like database, we use Docker (mainly [**Docker Compose**](https://docs.docker.com/compose/)).

- **(A)** Developing With Development Container

  - [Visual Studio Code](https://code.visualstudio.com/)

    Basically **VS Code Development Container** provides rich features such as git configuration and GPG sharing. But they sometimes require you to install some tools based on your device. Please check [this](https://code.visualstudio.com/docs/remote/containers#_sharing-git-credentials-with-your-container).

- **(B)** Developing Locally

  - [Go](https://go.dev/)

  - (_opt._) [ChromeDriver](https://chromedriver.chromium.org/home)

    > We recommend to use **Selenium Grid** on Docker (It is already configured in our [docker-compose.yml](./docker-compose.yml)) instead of using Web Driver Binary.

After you installed all above, then follow next steps based on your choice (A, B):

#### **(A)** Developing With Development Container

We configured all basic tools to be installed inside devcontainer, such as **pre-commit**.

1. Install VS Code extension **Remote - Containers (by Microsoft)**.

1. Then, clone this repository and open in VS Code, select **Remote-Containers: Reopen in Container...** at command palette (<kbd>ctrl</kbd> + <kbd>shift</kbd> + <kbd>P</kbd> or <kbd>cmd</kbd> + <kbd>shift</kbd> + <kbd>P</kbd>).

1. Done. Container includes required tools such as **pre-commit**, so you are ready to code.

   > To reduce load on your system, devcontainer is configured to not to start service **chrome-video** as it would might create huge recording files as time goes on.

#### **(B)** Developing Locally

1. Run `make install`

1. Run `make init`

1. Done. all other configurations are on your own. Or, you can use existing docker compose file to create dependent services (but would require some configuration changes).

#### **(C)** Remote Environment: GitHub Codespace or GitPod

In consideration but not ready to adopt it yet.

### 💯 pre-commit

We are using [pre-commit](https://pre-commit.com/) to check common lint errors and for code formatting. If using devcontainer, it is installed by default. Otherwise you should install it by yourself.

What you have to do is just run `pre-commit install` (or `make init`)

### 🐋 Docker Compose

You can see composed environment at [docker-compose.yml](./docker-compose.yml) file. To say shortly, exposed services would be:

- **crawler** (gRPC server) at port **50051**

- **selenium-hub** web UI at port **4444**

- **chrome** noVNC web at port **7900**

You could access to web UI via browsers. If are using Docker based on VM (like **Docker ToolBox**), localhost won't work for you. Follow [this](https://stackoverflow.com/a/42886035).

### ⏺️ Video Record

If you are using our compose script (not for devcontainer) and haven't manually excluded **chrome-\*-video** services, you might find video records of webdriver activities with filename **selenium/videos/chrome-\*.mp4** from project root directory.

### ⌨️ Basic Commands

Convenience scripts are defined in [Makefile](./Makefile) at project root. `make` without arguments will show you possible commands.
