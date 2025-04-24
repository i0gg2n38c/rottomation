for i in {1..20}; do docker kill "automation_devcontainer-firefox-${i}"; done
docker kill selenium-hub
# docker kill automation_devcontainer-app-1

