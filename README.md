# Ansible Test Suite


## Description

This repository provides docker based utilities for tesing Ansible roles

## Usage

The [`Makefile`](./Makefile) can be used to run tests of your playbooks.
It provides several targets corresponding to project's lifecycle.

Use `make` to run [default (`wip`)](#wip) target or specify a target.

### `base`

Build static dockerfiles (in [`ansible`](./ansible) directory) required
for custom images refrenced in [`compose` file](./docker-compose.yml).

Base image tagged `remote-runner` uses `ansible` version avalaible in
distribution (`2.7.2` from `epel` repository on CentOS)

Custom `ansible` version (the one used actually used on your project)
may be built by providing `ANSIBLE_VERSION` in [environment variables
file](./env)

### `build`

**Dependencies** : `clean base`

Build custom images refrenced in [`compose` file](./docker-compose.yml).

Custom images in `compose` file should be used when specific restrictions
applies to your project (custom repositories / packages / users) as provided
by project's infrastructure provider.

In that case, a `build` section must be declared on affected services.

*Eg. Custom ansible controller image*

```YAML
  ansible:
    build:
      context: my-awesowme-project/
      dockerfile: my-awesome.dockerfile
    image: ansible/my-awesome:image
    (...)
```

:bulb: If the only requirement of your project is custom `ansible` version, you
should probably won't need to build custom image (other than the one built
with `ANSIBLE_VERSION` environment variable).

### `clean`

**Dependencies**: `down`

Remove unused docker objects

### `debug`

Run tasks with `wip` tags from main playbook in *verbose* mode (`-vvv`)

### `down`

Stop and remove containers and networks for services defined in [`compose`
file](./docker-compose.yml)

Orphaned containers (in case you updated your services or project name)
are also removed.

### `full`

**Dependencies**: `up`

Run all main playbook's task (incuding tasks with `skip` tags).

### `init`

**Dependencies**: `build up`

Initialize containers with :

- custom initialization playbook
- tasks from main playbook with initialization tags defined in `ANSIBLE_INIT_TAGS` variable

### `play`

**Dependencies**: `up`

Run all main playbook's tasks (excluding tasks with tags define in `SKIP_TAG` variables)

### `test`

**Dependencies**: `up`

Test Ansible connectivity in both `ansible` controller container with `local` connection and
remote managed containers with `SSH` connections.

### `up`

Start containers

### `wip`

**Dependencies**: `up`

Run tasks with `wip` tags from main playbook. This target allows faster playbook run on **w**ork
**i**n **p**rogress tasks only.

:bulb: This target triggers ansible's `--diff`/`-D` option to highlight changes on you WIPs.
If you need more verbosity, use [`debug`](#debug) target.

:bulb: Handlers for WIP tasks will be run in case of change, comment them out for faster runs.

:warning: Before validating your WIP tasks in version control, don't forget to :
- remove `wip` tags
- enable commented handlers
- remove dead code (usually commented out  during debug process :bowtie:)

### Shorthand targets

`Makefile` provides some shorthands targets for convenience :

- `clean-debug` runs `init` and `debug` targets
- `clean-full` runs `init` and `full` targets
- `clean-play` runs `init` and `play` targets
- `clean-test` runs `build`, `up` and `test` targets
- `clean-wip` runs `init` and `wip` targets
- `check` runs `clean-test` and `down` targets

## Configuration

Playbook runs can be customized to suit your projects specific requirements in 3 places:

- [Environment file](./.env)
- [`Makefile`](./Makefile)
- [`Compose` file](./docker-compose.yml)

### Environment file

This file contains variables used both in MakeFile, Compose file and custom DockerFiles

| Variable        | Description                                                               |
| :---            | :-------                                                                  |
| `VAULT_KEY`     | Path to Ansible `vault-password-file`  used to project's sensitive data   |
| `PROJECT_HOME`  | Path to project's Ansible deployment code                                 |
| `ANSIBLE_USER`  | User used in project for ansible deployment                               |
| `PLAYBOOK_HOME` | Path to project's deployment code mounted in ansible controller container |

### `Makefile`

Variables in `Makefile` allows to customize playbook runs to best suit your project's infrastructure code.

#### Common Docker parameter

Variables in this section changes containers behaviour.


| Variable               | Description                                                                   |
| :---                   | :-------                                                                      |
| `COMPOSE_PROJECT_NAME` | Project's identifier used as prefix on containers started by `docker-compose` |

:bulb: Choose a short name without special characters to keep container names human readable !

#### Initialization playbook parameters

Variables in this section affects pre-initialization task run with `init` and dependant targets.

| Variable                 | Description                                                        |
| :---                     | :-------                                                           |
| `ANSIBLE_INIT_EXTRAVARS` | Extra variables used by initialization tasks (on `init` target)    |
| `ANSIBLE_INIT_PLAYBOOK`  | Filename of initialization playbook to use by Initialization tasks |
| `ANSIBLE_INIT_TAGS`      | Tags used to filter initialization tasks on main playbook          |

:bulb: In case no specific initialization is required (ie. target infrastructure is entirely reproducable
in managed containers images), `ANSIBLE_INIT_PLAYBOOK` can be set to `ANSIBLE_PLAY_PLAYBOOK`. Just make sure
main playbook doesn't contain tasks with `init` tag. In that particular case, you can adjust `ANSIBLE_INIT_TAGS`
with a custom tag not used in main playbook.

#### Regular playbook parameters

Variables in this section affects regular playbook runs

| Variable                 | Description                                                                               |
| :---                     | :-------                                                                                  |
| `ANSIBLE_PLAY_EXTRAVARS` | Extra variables used in containers to override actual infrastructure inventory variables  |
| `ANSIBLE_PLAY_PLAYBOOK`  | Main playbook filename                                                                    |
| `SKIP_TAGS`              | Tags used to filter skipped tasks on debug targets (`wip`, `debug` and dependant targets) |
| `DBG_OPTIONS`            | `ansible-playbook` options used in `debug` and dependant targets                          |
| `WIP_OPTIONS`            | `ansible-playbook` options used in `wip` and dependant targets                            |

### Compose file

Compose file affects *only* the infrastructure against which playbooks will be tested. The default
`services` provided in this repository can only be used **as-is** in single server infrastructures.

There's no actual additional parameters (aside from defining your services) to set in Compose file.

#### Services

Make sure your services are as close as possible of target infrastructure :

- same roles for each service, same number of containers...
- if target infrastructure relies on third-party services provided by infrastructure provider
(eg. managed DB servers), take advantage of community images available on [DockerHub][DOCKER_HUB]
to minimize setup tasks.

#### Ansible controller container

The following volumes are required to be mounted on `ansible` container :

| Volume destination   | Type                    | Description                                                                      |
| :---                 | :---:                   | :----------                                                                      |
| `/extra_vars`        | :file_folder:           | Directory containing extra variable files to override actual inventory variables |
| `/etc/ansible/hosts` | :page_facing_up:        | Inventory file to use with `ansible-playbook`                                    |
| `/run/secrets/vault` | :page_facing_up: :lock: | `vault-password-file` used to unlock sensitive data                              |
| `${PLAYBOOK_HOME}`   | :file_folder:           | Directory location for playbook files                                            |

:warning: For file (:page_facing_up:) mountpoints, make sure source file exists before running
`build` or dependant targets. Otherwise,

- Docker will create a directory at that location
- Ansible will fail complaining that it's expecting a file at that location and found a folder

:bulb: Unless your main playbook is located in project's subdirectory, default `${PROJECT_HOME}`
mountpoint should be fine.

:bulb: `${VAULT_KEY}` file is mounted read-only (:lock:) in `ansible` container. Keep it read-only
to avoid alteration inside container. If this happen, you **may loose access to your vault-encrypted**
file or variables.

#### Managed containers

Make sure `hostname` and `networks.default.aliases` uses the same name as actual managed servers as
defined in inventory file.

To allow `SSH` daemon to run,

- container must be `privileged`
- `/sys/fs/cgroup/` must be mounted from host

If one of these two items are missing, ansible will not be able to connect to managed containers over SSH.

## License

[Apache 2][APACHE2]

## Maintainer information

Hery Njato RANDRIAMANAMIHAGA (@heran / [@hr15a][GH_HR15A])

[//]: Bookmarks

[DOCKER_HUB]: http://hub.docker.com/
[APACHE2]: https://www.apache.org/licenses/LICENSE-2.0
[GH_HR15A]: https://github.com/hr15a
