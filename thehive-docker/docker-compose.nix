{ port, host, JOB_DIRECTORY, cortexConf, thehiveConf }:
''version: "3"
services:
  elasticsearch:
    image: elasticsearch:7.9.1
    environment:
      - http.host=0.0.0.0
      - discovery.type=single-node
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    ports:
      - "0.0.0.0:9200:9200"
  #https://github.com/TheHive-Project/CortexDocs/blob/master/installation/install-guide.md
  cortex:
    image: thehiveproject/cortex:latest
    depends_on:
      - elasticsearch
    command:
      --job-directory ${JOB_DIRECTORY}/cortex
    environment:
      - 'JOB_DIRECTORY=${JOB_DIRECTORY}'
    volumes:
      - '${cortexConf}:/etc/cortex/application.conf'
      - '${JOB_DIRECTORY}/cortex:${JOB_DIRECTORY}/cortex'
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "0.0.0.0:9001:9001"
  #https://docs.thehive-project.org/thehive/user-guides/quick-start/#first-login
  #login: admin@thehive.local
  #password: secret
  thehive:
    image: thehiveproject/thehive4:latest
    depends_on:
      - elasticsearch
      - cortex
    ports:
      - "0.0.0.0:9000:9000"
    volumes:
      - ${thehiveConf}:/etc/thehive/application.conf
      - ${JOB_DIRECTORY}:/opt/thp/thehive/db
      - ${JOB_DIRECTORY}:/opt/thp/thehive/data
      - ${JOB_DIRECTORY}:/opt/thp/thehive/index
    command: --cortex-port 9001
''
