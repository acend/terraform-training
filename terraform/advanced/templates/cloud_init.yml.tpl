#cloud-config
package_upgrade: true
packages:
  - docker.io
write_files:
  - path: /etc/cron.d/cleanup_docker_images
    owner: root:root
    content: |
      0 22 * * * root docker system prune --volumes --force --all >/dev/null 2>&1
  - path: /etc/docker/daemon.json
    owner: root:root
    content: |
      { "data-root": "/mnt/docker" }
runcmd:
  - wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
  - chmod +x /usr/local/bin/gitlab-runner
  - useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  - /usr/local/bin/gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  - /usr/local/bin/gitlab-runner start
  - /usr/local/bin/gitlab-runner register
      --non-interactive
      --executor docker
      --docker-privileged
      --docker-image docker:latest
      --name ${gitlab_runner_id}
      --url ${gitlab_url}
      --registration-token ${gitlab_runner_token}
      --docker-volumes "/certs/client"
%{ if gitlab_tag_list != null ~}
      --tag-list ${gitlab_tag_list}
%{ endif ~}