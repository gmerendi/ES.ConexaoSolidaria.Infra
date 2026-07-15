# Como rodar o projeto

Existem 3 maneiras de rodar o projeto: <br>
- Docker-compose : Cria containers no docker desktop, não gerenciados. Essa é a forma mais simples, com apenas 1 comando.
- Kubernetes local: Cria os deployments kubernetes localmente, utilizando a instalação kubernetes monitorada no docker desktop.
- AWS Cloud: Cria os deployments kubernetes no cloud AWS, utilizando serviços no cloud como alternativa para os serviços locais.  Requer criação prévia da Infra no AWS.

Inicialmente, todos os projetos precisam ser clonados, respeitando a hierarquia de pastas abaixo: <br>
C:\FIAP\ <br>
|---- ES.ConexaoSolidaria.Usuarios <br>
|---- ES.ConexaoSolidaria.Campanhas <br>
|---- ES.ConexaoSolidaria.Infra <br>
|---- ES.ConexaoSolidaria.Notificacoes <br>
|---- ES.ConexaoSolidaria.Worker <br>
|---- ES.ConexaoSolidaria.Gateway <br>
|---- ES.ConexaoSolidaria.Frontend <br>
|---- ES.ConexaoSolidaria.DynamoPgProxy <br>

<br>

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
4. Verifique os status dos pods com o comando abaixo.  Aguarde até que todos fiquem com status Running e Ready (1/1), exceto o cs-zabbix-init, que ficará com status Completed: <br>

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
kubectl create configmap cs-grafana-alerts-config --from-file=conexao_solidaria_alerts.yaml=docker-compose/observability/grafana/provisioning/alerting/alerts.yaml
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
kubectl delete configmap cs-grafana-alerts-config
kubectl delete -f k8s/local/services/cs-secrets.yaml
kubectl delete -f k8s/local/services/cs-services.yaml
kubectl delete -f k8s/local/services/cs-volumes.yaml

```


---
## AWS Cloud

### Como criar a configuração no AWS

#### 1.0 Pré-requisitos

Para preparar o ambiente de infraestrutura, siga os passos abaixo:

#### 1.1) Baixar o Terraform
Acesse o site oficial da HashiCorp e realize o download da versão estável mais recente para o seu sistema operacional:
👉 [Download Terraform Oficial](https://developer.hashicorp.com/terraform/install)

#### 1.2) Instalação Manual (Raiz da Infra)
Após baixar o arquivo, extraia o conteúdo e mova o executável para a pasta de infraestrutura do projeto:

* **Destino:** Salve o arquivo `terraform.exe` na raiz da pasta `/infra`.

```bash
# Estrutura esperada:

├── docker-compose/
├── docs/
├── k8s/
└── infra/
   ├── modules
   ├── terraform.exe  <-- O arquivo deve estar aqui
   ├── locals.tf
   ├── main.tf
   ├── providers.tf
   ├── terraform.tfvars
   └── variables.tf

```

#### 1.3) Crie uma conta mailtrap
Acesse https://mailtrap.io/ e crie uma conta.
<br/>
Na página home, clique em E-mail API/SMTP.
<br/>
<img width="1889" height="412" alt="image" src="https://github.com/user-attachments/assets/b5185ccd-ebc6-42bb-8624-fb1be3a59014" />
<br/>
<br/>
Siga os passos para criar uma api e anote o token e inbox ID.

#### 1.4) Crie o arquivo terraform.tfvars a partir do arquivo terraform.tfvars.example
Insira os dados de sua configuracao <br>
<img width="669" height="313" alt="image" src="https://github.com/user-attachments/assets/f536b0d9-bf73-42aa-bdc0-d33a8bd953d8" />


### 2.0 Laboratório AWS

Para iniciar o Laboratório AWS, siga os seguintes passos abaixo:

#### 2.1) Acesse o Laboratorio utilizando suas credenciais

#### 2.2) No laboratorio, clique em Start Lab
<img width="1799" height="353" alt="image" src="https://github.com/user-attachments/assets/25e39fc7-4578-4db5-a371-9a5004b5f091" />

#### 2.3) Após o ícone do AWS ficar verde, clique em AWS Details e AWS Cli Show
<img width="1799" height="421" alt="image" src="https://github.com/user-attachments/assets/be5b31b8-264b-483e-9c7d-27cb89a2020f" />

<br/>

Copie os dados de:<br/>
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_SESSION_TOKEN
<br/>
Copiar o Account ID:<br/>
<img width="804" height="211" alt="image" src="https://github.com/user-attachments/assets/e434a65d-7eba-4f63-8e16-314718e6d9d5" />

### 3.0 Criando Infra utilizando o terraform
#### 3.1) Insira os dados da AWS
Abra um terminal **PowerShell** na pasta `terraform`:<br/><br/>
<img width="561" height="506" alt="image" src="https://github.com/user-attachments/assets/2863b293-c853-4394-823a-80d009108ea4" />

<br/>

E digite:<br/>

```powershell
aws configure
```

Insira os dados conforme solicitados.
<br/>
<br/>

#### 3.2) Troque os dados da conta AWS nos secrets de repositorios
- Usuarios
- Campanhas
- Worker
- DynamoPgProxy
- Frontend
<BR>
<img width="3374" height="1968" alt="image" src="https://github.com/user-attachments/assets/ca7023ea-4131-44ff-8318-fa80fe5d7569" />



<br/>
<br/>


#### 3.3) Rode o terraform
No powershell aberto na pasta infra, digite o comando:
```powershell
.\terraform init
```
Ao final será mostrada a mensagem que o terraform está inicializado:<br/>
<img width="578" height="153" alt="image" src="https://github.com/user-attachments/assets/68db0652-9c57-4db4-bcb4-cbb9d7b9a20c" />

<br><br>

No powershell aberto na pasta infra, digite o comando:
```powershell
.\terraform apply
```
<br>
O terraform irá verificar na conta se ja existe algum hardware criado, criando o plano e irá perguntar se pode realizar as ações.
Responda "yes":<br/>
<img width="487" height="384" alt="image" src="https://github.com/user-attachments/assets/442d1a34-9dfa-41a3-a81f-e8c78575b4fd" />

<br/>
<br/>
Ao término da geração do hardware, ele irá mostrar o que foi criado:<br/>
<img width="690" height="351" alt="image" src="https://github.com/user-attachments/assets/6e806659-67fd-4d97-90ca-cd4b2ffa0887" />


<br/>
<br/>

#### 3.4) Verificar o email cadastrado no terraform
O email inserido nesse campo será o e-mail utilizado para os testes de notificação:<br>
<img width="541" height="275" alt="image" src="https://github.com/user-attachments/assets/115027b0-bef7-4a9f-ab50-7efa8245c5fd" />
<br>
Acesse o e-mail configurado e verifique aceite a subscrição proveniente da AWS. Caso esse passo não seja feito, os e-mails de notificação não serão enviados.<br>
<img width="1425" height="655" alt="image" src="https://github.com/user-attachments/assets/60becc57-a7a1-48a9-8ed7-e79f70f168c5" />


<br><br>
#### 3.5) Fazer update de contexto do Kubernetes (EKS)
```powershell
aws eks update-kubeconfig --region us-east-1 --name cs-cluster
```

#### 3.6) Fazer deploy dos manifestos Kubernetes
Abra um powershell na raiz e digite os comandos abaixo:
```powershell
kubectl create configmap cs-grafana-user-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/usuarios-api.json
kubectl create configmap cs-grafana-campaign-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/campanhas-api.json
kubectl create configmap cs-grafana-donation-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/donationworker.json
kubectl create configmap cs-grafana-zabbix-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/zabbix.json
kubectl create configmap cs-grafana-app-logs-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/cs-app-logs.json
kubectl create configmap cs-grafana-audit-log-dash --from-file=docker-compose/observability/grafana/provisioning/dashboards/cs-audit-log.json
kubectl create configmap cs-grafana-alerts-config --from-file=conexao_solidaria_alerts.yaml=docker-compose/observability/grafana/provisioning/alerting/alerts.yaml


kubectl apply -f k8s/aws/services/cs-configmap.yaml
kubectl apply -f k8s/aws/services/cs-configzabbix.yaml
kubectl apply -f k8s/aws/services/cs-configobs.yaml
kubectl apply -f k8s/aws/services/cs-secrets.yaml
kubectl apply -f k8s/aws/services/cs-services.yaml
kubectl apply -f k8s/aws/services/cs-volumes.yaml
kubectl apply -f k8s/aws/services/cs-elasticsearch.yaml
kubectl apply -f k8s/aws/services/cs-zabbix.yaml

```
<br><br>
Aguarde os pods acima ficarem prontos - Status= Running, READY 1/1 (zabbix leva uns 3.5 minutos):<br>
Teste com o comando:
```powershell
kubectl get pods
```
<br>
Obs.: O POD cs-zabbix-init roda apenas na inicialização do zabbix para configurá-lo e pára, portanto o STATUS será Completed.
<BR>
<img width="556" height="120" alt="image" src="https://github.com/user-attachments/assets/9a7aebb1-50e5-4f2a-ba16-69a9373f109b" />
<br><br>

#### 3.7) Insira os serviços dos microserviços no api gateway
Abra um powershell na raiz e digite os comandos abaixo:
```powershell
kubectl get svc

```
<br><br>
Copie os endereços dos micro-serviçoes de campanhas,  usuários e frontend no arquivo variables.tf na raiz da pasta terraform e passe a variável deploy_apigw para true: <br>
<img width="2437" height="933" alt="image" src="https://github.com/user-attachments/assets/eae88048-0e0b-4df1-8f47-75cbbb9fdd07" />



<br><br>
Faça o terraform apply novamente , abrindo um powershell na pasta terraform:<br>
```powershell
.\terraform apply
```
<br>
O api gateway será criado.<br>
<img width="696" height="305" alt="image" src="https://github.com/user-attachments/assets/d00a1fc8-01b1-4af7-93d3-b0ed5c2f6065" />
<br><br>

#### 3.8) Obtenha a URL do API Gateway para ser inserida no arquivo cs-configmap.yaml
Para descobrir o endereço do API Gateway:<br>
```powershell
$apiId = aws apigatewayv2 get-apis --query "Items[0].ApiId" --output text
$stage = aws apigatewayv2 get-stages --api-id $apiId --query "Items[0].StageName" --output text
$endpoint = "https://$apiId.execute-api.us-east-1.amazonaws.com/$stage"
Write-Host "Endpoint: $endpoint"

```
<img width="1106" height="115" alt="image" src="https://github.com/user-attachments/assets/198078aa-fda4-40b6-868b-988f43366ff8" />

<br><br>


#### 3.9) Modifique o arquivo k8s/aws/services/cs-configmap e modifique os dados abaixo com os endereços do AWS:
<img width="875" height="501" alt="image" src="https://github.com/user-attachments/assets/dc4ef39e-71ba-4ff2-a540-f8be861bfbd5" />
<br>
Efetue o deploy do configmap novamente <br>

```powershell
kubectl apply -f k8s/aws/services/cs-configmap.yaml
```

#### 3.10) Rode o Workflow de todos os repositórios de microserviços:
É necessário rodar apenas o CD.  Como o CD tem como pré-requisito o CI, ambos vao rodar no workflow.<br>
[cd.yml — ES.ConexaoSolidaria.Usuarios](https://github.com/gmerendi/ES.ConexaoSolidaria.Usuarios/actions/workflows/cd.yml)<br>
[cd.yml — ES.ConexaoSolidaria.Campanhas](https://github.com/gmerendi/ES.ConexaoSolidaria.Campanhas/actions/workflows/cd.yml)<br>
[cd.yml — ES.ConexaoSolidaria.Worker](https://github.com/gmerendi/ES.ConexaoSolidaria.Worker/actions/workflows/cd.yml)<br>
[cd.yml — ES.ConexaoSolidaria.DynamoPgProxy](https://github.com/gmerendi/ES.ConexaoSolidaria.DynamoPgProxy/actions/workflows/cd.yml)<br>
[cd.yml — ES.ConexaoSolidaria.Frontend](https://github.com/gmerendi/ES.ConexaoSolidaria.Frontend/actions/workflows/cd.yml)<br>

<img width="3685" height="1118" alt="image" src="https://github.com/user-attachments/assets/de4b91a1-01c4-4264-9b03-906b754b48cc" />


<br><br>


Os workflows vão dar deploy automatico nos serviços.<br>

Aguarde os pods ficarem prontos:<br>
Teste com o comando:
```powershell
kubectl get pods
```
<br>
<img width="539" height="166" alt="image" src="https://github.com/user-attachments/assets/cbd922b4-dd0e-42c4-b379-6234378e5530" />

<br><br>

O Frontend pode ser utilizado na url: <cs-frontend-svc.EXTERNAL-IP>:3000<br><br>

<img width="1171" height="142" alt="image" src="https://github.com/user-attachments/assets/ec8a8a42-5017-46de-b59a-ad851fb89497" />
<br>

<img width="2551" height="976" alt="image" src="https://github.com/user-attachments/assets/79a2af51-e3b4-454e-8502-b5b60cbd89b6" />
<br><br>


<br><br>
#### 3.12) Efetue o deploy da Observabilidade
```powershell
kubectl apply -f k8s/aws/services/cs-prometheus.yaml
kubectl apply -f k8s/aws/services/cs-grafana.yaml
```
<br>
---


## Utilizando a aplicação
Os micro-serviços de usuários e campanhas, não são acessíveis diretamente no browser, por serem internos. Eles são acessíveis via Gateway no endereço:
```
localhost:5006/swagger/index.html
```
Selecione o micro-serviço no dropdown "select a definition":<br>
<img width="2544" height="992" alt="image" src="https://github.com/user-attachments/assets/f9d54c44-03b0-4bc3-9801-94fdb29c6444" />

<br><br>
Um usuário administrador é criado no deploy para que seja possivel a criação de Campanhas.  O password, nome e CPF desse usuário devem ser modificados após sua autenticação, no primeiro acesso:
```
{
  "email": "admin@conexao-solidaria.com.br",
  "password": "12345678Aa#"
}
```
<br>
Após realizar o login, um token é retornado: <br>
<img width="1490" height="199" alt="image" src="https://github.com/user-attachments/assets/69b998ff-921b-4bd2-abc2-a869246261b3" />

<br><br>
Utilize esse token para realizar a autorização no swagger. Não é necessária a autorização em ambos serviços. Se o token foi autorizado no Usuários, também funciona para campanhas.<br>
<img width="1207" height="454" alt="image" src="https://github.com/user-attachments/assets/fb667cc0-59ec-43c3-9ccd-f01c71b30b4c" />
<br><br>

Um email é enviado como notificação ao se criar um novo usuário ou se efetuar uma doação.  O e-mail pode ser verificado na url abaixo, que abrirá o Mailpit, onde pode ser verificar o e-mail enviado e seu conteúdo: <br>
```
http://localhost:8025/
```
<br>
<img width="2549" height="700" alt="image" src="https://github.com/user-attachments/assets/38474614-381b-4efd-a4cb-4151db44f40c" />

<br><br>
Embora a porta do serviviço de mensageria AMQP seja interna por motivos de segurança, as mensagens enviadas para o RabbitMq podem ser verificadas no painel de monitoramento:
```
http://localhost:15672/
```
<br>

O usuario e password utilizados (caso não tenham sido substituidos no arquivo de secret) são:<br>

- user: fiap
- password *: fiap123


<br><br>
<img width="2549" height="840" alt="image" src="https://github.com/user-attachments/assets/4ae252cf-697d-4cfb-b22f-90ff246e1ec8" />
<br><br>

A Observabilidade pode ser acessada através do Grafana, na url:<br>
```
http://localhost:3000/login
```
<br>
O usuario e password utilizados (caso não tenham sido substituidos no arquivo de secret) são:<br>

- user: fiap
- password *: fiap123

<br>
<img width="2556" height="648" alt="image" src="https://github.com/user-attachments/assets/8618bf80-a9ad-4939-92a9-63e1948a5ee2" />
<br><br>

O Frontend da aplicação pode ser acessado na url abaixo.  Para acessar, cadastre um novo usuário clicando em cadastrar ou acesse clicando em portal do usuário. <br>
```
http://localhost:5000
```
<br>
<img width="2543" height="991" alt="image" src="https://github.com/user-attachments/assets/81260fc6-009c-4f1e-a068-fd378a761c0e" />
