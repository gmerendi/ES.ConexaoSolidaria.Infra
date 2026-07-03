# Como rodar o projeto

Existem 3 maneiras de rodar o projeto: <br>
- Docker-compose : Cria containers no docker desktop, não gerenciados. Essa é a forma mais simples, com apenas 1 comando.
- Kubernetes local: Cria os deployments kubernetes localmente, utilizando a instalação kubernetes monitorada no docker desktop.
- AWS Cloud: Cria os deployments kubernetes no cloud AWS, utilizando serviços no cloud como alternativa para os serviços locais.  Requer criação prévia da Infra no AWS.

---

## Sumário
- [Docker-Compose](#docker-compose)
- [Kubernetes Local](#kubernetes-local)
- [AWS Cloud](#aws-cloud)
- [Utilizando a aplicação](#utilizando-a-aplicação)
---

## Docker-Compose
Para rodar o docker-compose é necessário o Docker desktop versao 4.79.0: <br>
<img width="2537" height="606" alt="image" src="https://github.com/user-attachments/assets/7585a1bc-5e0a-4962-b70d-c9c70d446bfd" />
<br>

O projeto Conexão Solidária será criado contendo os seguintes containers:
- cs-usuarios-api : Responsável pelo gerenciamento de usuários e autenticação
- cs-campanhas-api : Responsável pelo gerenciamento de campanhas e doações
- cs-donationworker-api : Responsável pelo consumo de intenção de doaçao gerada na campanha e gravação em banco de dados
- cs-notificacoes : Responsável pelo envio de e-mails de notificação aos usuários
- cs-gateway-api : Api Gateway responsável pelo gerenciamento de conexão para os micro-serviços
- cs-redis : Responsável pelo cache da aplicação
- cs-elasticsearch : Mecanismo de busca e análise de dados tolerante à erros de digitação.
- cs-dynamo-db : Base de Dados NoSQL responsável pelo amazenamento de logs de aplicação e auditoria.
- cs-usuarios-db : Base de dados PostGreSQL responsável pelo armazenamento de dados de usuarios
- cs-campanhas-db : Base de dados PostGreSQL responsável pelo armazenamento de dados de campanhas e doações
- cs-mailpit : Aplicação Frontend Conexão Solidária
- cs-rabbitmq : Broker de mensageria
- cs-zabbix : Plataforma de monitoramento de infraestrutura de TI
- cs-zabbix-agent : Coletor de dados para o Zabbix.
- cs-zabbix-init : Inicializador de configuração do zabbix. Não permanece rodando.  Parte, configura o zabbix e para.
- cs-prometheus : Plataforma de monitoramento para coleta de métricas.
- cs-grafana : Plataforma de observabilidade que gera gráficos e alertas baseados em dados provenientes do Zabbix, Prometheus e Dynamo (logs)
<br>
O projeto é criado de acordo com essa arquitetura local: <br>
* TODO * <br>

### Como criar a configuração no docker-compose
1. Abrir terminal na pasta docker-compose e rodar o comando:<br>
```powershell
docker-compose up -- build
```
<img width="552" height="412" alt="image" src="https://github.com/user-attachments/assets/31fdf045-4c6c-4a79-9f5f-8f39b8bf43ed" />
<br>
2. Vá para a seção - [Utilizando a aplicação](#utilizando-a-aplicação) para saber como chamar cada componente no browser

### Como deletar a configuração no docker-compose
1. No mesmo terminal aberto na pasta docker-compose:
```Powershell
docker-compose down -v
```

---
## Kubernetes Local
Para rodar o projeto em kubernetes localmente é necessário o Docker desktop versao 4.79.0, com Kubernetes versão 134.3 configurado com um cluster kind com dois nodes - control-plane e worker: <br>
<img width="2542" height="1027" alt="image" src="https://github.com/user-attachments/assets/b4977b54-7867-43e5-8eba-1eb595a0fc23" />

<br>

O projeto Conexão Solidária será criado contendo os seguintes artefatos:
- ConfigMaps
- Secrets
- Pods
- Deployments
<br>

Cada deployment contém um container, conforme listado na seção Docker-compose. <br>

### Como criar a configuração no Kubernetes local
1. Criar imagens Docker <br>
Abrir terminal na pasta docker-compose e rodar o comando:
```powershell
docker-compose build
```

2. Abrir Terminal na raiz<br>
<img width="592" height="273" alt="image" src="https://github.com/user-attachments/assets/1ff1dab3-ae64-4e5d-aba6-f87287ce6255" />
<br><br>

3. Digite os comandos a seguir para criar a infraestrutura basica:
```powershell
 kubectl apply -f k8s/local/services/cs-aws-credentials.yaml
 kubectl apply -f k8s/local/services/cs-aws-accounts.yaml
 kubectl apply -f k8s/local/services/cs-configmap.yaml
 kubectl apply -f k8s/local/services/cs-configproxy.yaml
 kubectl apply -f k8s/local/services/cs-configobs.yaml
 kubectl apply -f k8s/local/services/cs-secrets.yaml
 kubectl apply -f k8s/local/services/cs-services.yaml
 kubectl apply -f k8s/local/services/cs-volumes.yaml
 kubectl apply -f k8s/local/services/cs-rabbitmq.yaml
 kubectl apply -f k8s/local/services/cs-postgres.yaml
 kubectl apply -f k8s/local/services/cs-dynamo.yaml
 kubectl apply -f k8s/local/services/cs-redis.yaml
 kubectl apply -f k8s/local/services/cs-elasticsearch.yaml
 kubectl apply -f k8s/local/services/cs-mailpit.yaml
 kubectl apply -f k8s/local/services/cs-dynamo-proxy.yaml
 kubectl apply -f k8s/local/services/cs-configzabbix.yaml

 # zabbix pode demorar. configurado 3 minutos de startup
 kubectl apply -f k8s/local/services/cs-zabbix.yaml

```
<br>
4. Verifique os status dos pods com o comando abaixo.  Aguarde até que todos fiquem com status Running e Ready (1/1): <br>

```powershell
kubectl get pods
```

<img width="504" height="224" alt="image" src="https://github.com/user-attachments/assets/a405130a-4bed-4ed7-88ff-aefb5d92296b" />

<br><br>
5. Digite os comandos abaixo para criar os micro-serviços:<br>

```powershell
 kubectl apply -f k8s/local/services/cs-usuarios.yaml
 kubectl apply -f k8s/local/services/cs-campanhas.yaml
 kubectl apply -f k8s/local/services/cs-donationworker.yaml
 kubectl apply -f k8s/local/services/cs-notificacoes.yaml
 kubectl apply -f k8s/local/services/cs-gateway.yaml
 kubectl apply -f k8s/local/services/cs-frontend.yaml
 
```
<br>
6. Verifique os status dos pods com o comando abaixo.  Aguarde até que todos fiquem com status Running e Ready (1/1): <br>

```powershell
kubectl get pods
```
<img width="499" height="318" alt="image" src="https://github.com/user-attachments/assets/dd4c01f4-edaf-42d0-a48f-bb5476eb50b3" />
<br><br>

7. Digite os comandos abaixo para criar a observabilidade:<br>

```powershell
kubectl create configmap cs-grafana-user-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/usuarios-api.json
kubectl create configmap cs-grafana-campaign-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/campanhas-api.json
kubectl create configmap cs-grafana-donation-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/donationworker.json
kubectl create configmap cs-grafana-zabbix-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/zabbix.json
kubectl create configmap cs-grafana-app-logs-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/cs-app-logs.json
kubectl create configmap cs-grafana-audit-log-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/cs-audit-log.json
kubectl apply -f k8s/local/services/cs-prometheus.yaml
kubectl apply -f k8s/local/services/cs-grafana.yaml
 
```
<br>
8. Verifique os status dos pods com o comando abaixo.  Aguarde até que todos fiquem com status Running e Ready (1/1): <br>

```powershell
kubectl get pods
```
<img width="529" height="351" alt="image" src="https://github.com/user-attachments/assets/3ea0143e-7e85-430f-a4f4-c8111071f1fa" />

<br><br>


9. Vá para a seção - [Utilizando a aplicação](#utilizando-a-aplicação) para saber como chamar cada componente no browser
<br>

### Como deletar a configuração no kubernetes
1. No mesmo terminal aberto na raiz, digite os comandos abaixo:
```Powershell
kubectl delete -f k8s/local/services/cs-prometheus.yaml
kubectl delete -f k8s/local/services/cs-grafana.yaml

kubectl delete -f k8s/local/services/cs-frontend.yaml
kubectl delete -f k8s/local/services/cs-usuarios.yaml
kubectl delete -f k8s/local/services/cs-campanhas.yaml
kubectl delete -f k8s/local/services/cs-donationworker.yaml
kubectl delete -f k8s/local/services/cs-notificacoes.yaml
kubectl delete -f k8s/local/services/cs-gateway.yaml

kubectl delete -f k8s/local/services/cs-rabbitmq.yaml
kubectl delete -f k8s/local/services/cs-postgres.yaml
kubectl delete -f k8s/local/services/cs-dynamo.yaml
kubectl delete -f k8s/local/services/cs-redis.yaml
kubectl delete -f k8s/local/services/cs-elasticsearch.yaml
kubectl delete -f k8s/local/services/cs-mailpit.yaml
kubectl delete -f k8s/local/services/cs-dynamo-proxy.yaml

kubectl delete -f k8s/local/services/cs-configzabbix.yaml
kubectl delete -f k8s/local/services/cs-zabbix.yaml

kubectl delete -f k8s/local/services/cs-aws-credentials.yaml
kubectl delete -f k8s/local/services/cs-aws-accounts.yaml
kubectl delete -f k8s/local/services/cs-configmap.yaml
kubectl delete -f k8s/local/services/cs-configproxy.yaml
kubectl delete -f k8s/local/services/cs-configobs.yaml
kubectl delete configmap cs-grafana-user-dash
kubectl delete configmap cs-grafana-campaign-dash
kubectl delete configmap cs-grafana-donation-dash
kubectl delete configmap cs-grafana-zabbix-dash
kubectl delete configmap cs-grafana-app-logs-dash
kubectl delete configmap cs-grafana-audit-log-dash
kubectl delete -f k8s/local/services/cs-secrets.yaml
kubectl delete -f k8s/local/services/cs-services.yaml
kubectl delete -f k8s/local/services/cs-volumes.yaml

```


---
## AWS Cloud
1. Configurar conta AWS
aws configure 

2. Aplicar Terraform
.\terraform apply

2. Criar imagens Docker
Abrir terminal na pasta docker-compose e rodar o comando:
docker-compose build


3. Subir Imagens docker
 aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 641008666847.dkr.ecr.us-east-1.amazonaws.com

 docker tag cs-usuarios-api:latest 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-usuarios-api:latest
 docker tag cs-campanhas-api:latest 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-campanhas-api:latest
 docker tag cs-donationworker-api:latest 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-donationworker-api:latest

 docker push 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-usuarios-api:latest
 docker push 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-campanhas-api:latest
 docker push 641008666847.dkr.ecr.us-east-1.amazonaws.com/cs-donationworker-api:latest


 4. Conectar o Kubernetes no aws
 aws eks update-kubeconfig --region us-east-1 --name cs-cluster


 5. Inserir os dados de conta no cs-aws-credentials.yaml


 6. Abrir Terminal na raiz

 kubectl apply -f k8s/aws/services/cs-aws-credentials.yaml
 kubectl apply -f k8s/aws/services/cs-aws-accounts.yaml
 kubectl apply -f k8s/aws/services/cs-configmap.yaml
 kubectl apply -f k8s/aws/services/cs-configzabbix.yaml
 kubectl apply -f k8s/aws/services/cs-configobs.yaml
 kubectl apply -f k8s/aws/services/cs-secrets.yaml
 kubectl apply -f k8s/aws/services/cs-services.yaml
 kubectl apply -f k8s/aws/services/cs-volumes.yaml
 kubectl apply -f k8s/aws/services/cs-elasticsearch.yaml

  kubectl get pods

 * Aguardar os pods ficarem prontos

 kubectl apply -f k8s/aws/services/cs-usuarios.yaml
 kubectl apply -f k8s/aws/services/cs-campanhas.yaml
 kubectl apply -f k8s/aws/services/cs-donationworker.yaml

 kubectl apply -f k8s/aws/services/cs-zabbix.yaml
 kubectl apply -f k8s/aws/services/cs-prometheus.yaml
 kubectl apply -f k8s/aws/services/cs-grafana.yaml
 
 7. Dar deploy no Api Gateway

 kubectl get svc


 DELETAR
 kubectl delete -f k8s/aws/services/cs-usuarios.yaml
 kubectl delete -f k8s/aws/services/cs-campanhas.yaml
 kubectl delete -f k8s/aws/services/cs-donationworker.yaml
 


 kubectl delete -f k8s/aws/services/cs-aws-credentials.yaml
 kubectl delete -f k8s/aws/services/cs-aws-accounts.yaml
 kubectl delete -f k8s/aws/services/cs-configmap.yaml
 kubectl delete -f k8s/aws/services/cs-configzabbix.yaml
 kubectl delete -f k8s/aws/services/cs-secrets.yaml
 kubectl delete -f k8s/aws/services/cs-services.yaml
 kubectl delete -f k8s/aws/services/cs-volumes.yaml
 kubectl delete -f k8s/aws/services/cs-elasticsearch.yaml



## Utilizando a aplicação



 



