import json
import os
import boto3
from datetime import datetime
from botocore.exceptions import ClientError

# ========================================
# CONFIGURAÇÃO
# ========================================

sns_client = boto3.client('sns', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

# Cores ANSI para o Log (Estilo .NET Console)
COLOR_GREEN = "\033[32m"
COLOR_BG_BLACK = "\033[40m"
COLOR_RESET = "\033[39m\033[22m\033[49m"

# ========================================
# UTILITÁRIOS
# ========================================

def log_formatted(correlation_id, event_name, email):
    """Gera o log exatamente no formato solicitado"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    log_msg = (
        f"{timestamp} {COLOR_BG_BLACK}{COLOR_GREEN}info{COLOR_RESET}: "
        f"AWS.SQS: [CorrelationId: {correlation_id}] "
        f"Evento {event_name} lido da fila. Email enviado para: {email}"
    )
    print(log_msg)

def send_notification(to_email, subject, message_text):
    try:
        sns_client.publish(
            TopicArn = SNS_TOPIC_ARN,
            Subject  = subject,
            Message  = message_text
        )
        return True
    except ClientError as e:
        print(f"❌ Erro SNS: {e.response['Error']['Message']}")
        raise

# ========================================
# PROCESSADORES
# ========================================

def process_user_created(message_body):
    data = json.loads(message_body) if isinstance(message_body, str) else message_body
    
    email = data.get('email')
    nome  = data.get('nome', 'Doador')
    cpf  = data.get('cpf', 'Doador')
    corr_id = data.get('correlationId', 'N/A')

    if not email:
        raise ValueError("Email is required in UserCreatedEvent")

    subject = "Bem-vindo ao Portal Conexão Solidária"
    message_text = f"""
Olá, {nome}!

Seu usuário foi criado em nosso sistema com o cpf: {cpf}!
Utilize seu e-mail como login.
Verifique as campanhas ativas em nosso site acessando: https://www.conexaosolidaria.com.br



Atenciosamente,
Equipe Esperança Solidária
-----------------------------------------------------------
Este é um e-mail automático. Não é necessário respondê-lo.
"""
    
    if send_notification(email, subject, message_text):
        log_formatted(corr_id, "UserCreated", email)


def process_donation_processed(message_body):
    data = json.loads(message_body) if isinstance(message_body, str) else message_body
    
    email     = data.get('email')
    user_name = data.get('userName', 'Doador')
    campaign_name = data.get('campanhaTitulo', 'Titulo')
    valor = data.get('valor', '0')
    corr_id   = data.get('correlationId', 'N/A')

    if not email:
        raise ValueError("Email is required in DonationProcessedEvent")

    subject = f"Doação recebida!"

    message_text = f"""
Ola, "{user_name}"!

Sua doação de  "{valor}" foi confirmada para a "{campanhaTitulo}". 

Obrigado por fazer a diferença!


Equipe Esperança Solidária
-----------------------------------------------------------
Protocolo de Doação: {corr_id}
"""

    if send_notification(email, subject, message_text):
        log_formatted(corr_id, "DonationProcessedEvent", email)

# ========================================
# HANDLER PRINCIPAL
# ========================================

def handler(event, context):
    failed_messages = []

    for record in event['Records']:
        message_id = record['messageId']
        queue_arn  = record['eventSourceARN']
        body       = record['body']

        try:
            # Verifica qual fila disparou o evento baseado no ARN
            if 'user-created' in queue_arn.lower():
                process_user_created(body)
            elif 'donation-processed' in queue_arn.lower():
                process_game_purchased(body)
            else:
                print(f"⚠️ Fila desconhecida: {queue_arn}")

        except Exception as e:
            print(f"❌ Erro na mensagem {message_id}: {str(e)}")
            failed_messages.append({"itemIdentifier": message_id})

    if failed_messages:
        return {"batchItemFailures": failed_messages}

    return {'statusCode': 200, 'body': 'Processado'}