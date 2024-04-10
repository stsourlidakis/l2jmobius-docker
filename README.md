# L2jMobius Docker

This Docker configuration will help you run a server with [L2jMobius](https://l2jmobius.org/) in minutes without having to install each component separately.

[Demo Video](https://www.youtube.com/watch?v=S7KnK9tn89A)

## Instructions

1. [Install Docker](https://docs.docker.com/engine/install/)
2. [Download the L2jMobius source code](https://bitbucket.org/MobiusDev/l2j_mobius/downloads/)
3. Extract any of the chronicles to a new directory (See `readme.txt` on how to get the client+system)
4. Add the files from this directory next to the source code
5. Update any server configs or db credentials (`.env`) **[OPTIONAL]**
6. Open your terminal, navigate in the project's directory and run `docker-compose up -d --build`
7. You should be able to connect to the game, a phpMyAdmin instance is also running on http://localhost:8080

## Notes

- Some of your configs (username/password/db name/hostnames) will be ignored, values from `.env` will be used instead
- Inspired by [L2JMobius-on-rpi](https://github.com/Eptarch/l2jmobius-on-rpi/)
- License: [WTFPL-2.0](https://www.tldrlegal.com/license/do-wtf-you-want-to-public-license-v2-wtfpl-2-0)
