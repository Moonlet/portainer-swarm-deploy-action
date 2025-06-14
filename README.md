# Portainer swarm deploy action

Config example:
```yml
- name: Deploy in swarm
  uses: MoonletLabs/portainer-swarm-deploy-action@main
  with:
    portainer_url: ${{ env.PORTAINER_URL }}
    portainer_access_token: ${{ secrets.PORTAINER_ACCESS_TOKEN }}
    endpoint: ${{ env.ENDPOINT }}
    stack_name: ${{ env.STACK_NAME }}
    compose_file: ${{ env.COMPOSE_FILE }}
    env_file: ${{ env.DEPLOYMENT_PATH }}/${{ env.ENV_NAME_SHORT }}.env
```
