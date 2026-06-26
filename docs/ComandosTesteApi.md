# Usuarios 
Utilizar powershell para os comandos.

## 1. Descobrir o endpoint do API Gateway v2
$apiId = aws apigatewayv2 get-apis --query "Items[0].ApiId" --output text
$stage = aws apigatewayv2 get-stages --api-id $apiId --query "Items[0].StageName" --output text
$endpoint = "https://$apiId.execute-api.us-east-1.amazonaws.com/$stage"
Write-Host "Endpoint: $endpoint"



## 2. Obter o token
$body = '{"email":"admin@conexao-solidaria.com.br","password":"12345678Aa#"}'

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/auth/login" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body

$token = $response.token
Write-Host "Token obtido: $token"



## 3. Cadastrar usuário
$headers = @{ Authorization = "Bearer $token" }

$novoUsuario = @{
    nomeCompleto = "Jose Silva"
    email        = "jose.silva@gmail.com"
    cpf          = "28178329069"
    password     = "12345678Aa#"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario" `
  -Method POST `
  -ContentType "application/json" `
  -Headers $headers `
  -Body $novoUsuario

$response | ConvertTo-Json -Depth 10




## 4. Visualizar os dados de um Usuario
$headers = @{ 
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario?Email=$email" `
  -Method GET `
  -Headers $headers

$response | ConvertTo-Json -Depth 10




## 5. Suspender usuario
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario/suspender?Email=$email" `
  -Method PUT `
  -Headers $headers

$response | ConvertTo-Json -Depth 10




## 6. Ativar usuario
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario/ativar?Email=$email" `
  -Method PUT `
  -Headers $headers

$response | ConvertTo-Json -Depth 10



## 7. Alterar para gestor
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario/alterar-para-gestor?Email=$email" `
  -Method PUT `
  -Headers $headers

$response | ConvertTo-Json -Depth 10



## 8. Alterar para doador
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario/alterar-para-doador?Email=$email" `
  -Method PUT `
  -Headers $headers

$response | ConvertTo-Json -Depth 10



## 9. Alterar dados de usuario logado
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$nome = [Uri]::EscapeDataString("Fulano de Tal")
$cpf  = [Uri]::EscapeDataString("82705850090")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario/alterar?NomeCompleto=$nome&Cpf=$cpf" `
  -Method PUT `
  -Headers $headers

$response | ConvertTo-Json -Depth 10


## 10. Remover Usuario
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$email = [Uri]::EscapeDataString("jose.silva@gmail.com")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/usuario?Email=$email" `
  -Method DELETE `
  -Headers $headers

$response | ConvertTo-Json -Depth 10


## 11. Alterar password

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/json"
}

$body = @{
    passwordAtual = "12345678Aa@"
    passwordNovo  = "12345678Aa#"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/auth/reset-password" `
  -Method PUT `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" } `
  -Body $body

## Atualiza o token com o retorno do reset
$token = $response
Write-Host "Token renovado: $token"

12. Fazer logout
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/auth/logout" `
  -Method POST `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$token = $null
Write-Host "Logout realizado."


# Campanhas
## 1. Criar Campanha
$body = @{
    titulo         = "Crianca Esperanca"
    descricao      = "Uma campanha para arredacar doacoes para criancas"
    metaFinanceira = 2000
    dataInicio     = "2026-06-10T13:19:20.189Z"
    dataFim        = "2026-06-30T13:19:20.189Z"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas" `
  -Method POST `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" } `
  -Body $body

$response | ConvertTo-Json -Depth 10

# Guarda o guid para usar nas próximas operações
$guidCampanha = $response.value.guid
Write-Host "Guid da campanha: $guidCampanha"

## 2. Visualizar dados de uma campanha$guidCampanha = "5d3a0398-ac91-4ae0-93c7-2c5f5e39e852"

#$guidCampanha = "5d3a0398-ac91-4ae0-93c7-2c5f5e39e852"

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas?Guid=$guidCampanha" `
  -Method GET `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10



## 3. Alterar campanha

$body = @{
    guid           = $guidCampanha
    titulo         = "Titulo super modificado"
    descricao      = "Campanha para arrecadar fundos"
    metaFinanceira = 1000
    dataInicio     = "2026-06-26T20:40:31.983Z"
    dataFim        = "2026-06-30T20:40:31.983Z"
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas" `
  -Method PUT `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" } `
  -Body $body

$response | ConvertTo-Json -Depth 10



## 4. Listar campanhas ativas
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas/todas" `
  -Method GET `
  -Headers @{ Accept = "application/json" }

$response | ConvertTo-Json -Depth 10

## 5. Obter campanhas avancado (ElasticSearch)
$termo = [Uri]::EscapeDataString("supar")

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas/busca?Termo=$termo" `
  -Method GET `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10


## 6. Cancelar campanha
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas/cancel?Guid=$guidCampanha" `
  -Method PUT `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10

## 7. Cancelar campanha


## 8. Realizar doacoes
$guidCampanha = "45cd71e8-a3b1-47e0-8894-8ec70de37cf0"
$body = @{
    guid  = $guidCampanha
    valor = 100
} | ConvertTo-Json

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Doacoes" `
  -Method POST `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" } `
  -Body $body

$response | ConvertTo-Json -Depth 10


## 9. Concluir Campanha
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Campanhas/concluir?Guid=$guidCampanha" `
  -Method PUT `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10


## 10. Obter doacoes por campanha
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Doacoes/campanha?GuidCampanha=$guidCampanha" `
  -Method GET `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10


## 11. Obter doacoes por usuarios:
$guidUsuario = "8e98b418-9428-4879-a913-48cfa06be4e8"

$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Doacoes/usuario?GuidUsuario=$guidUsuario" `
  -Method GET `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10


## 12. Obter Proprias doacoes:
$response = Invoke-RestMethod `
  -Uri "$endpoint/api/v1/Doacoes/self" `
  -Method GET `
  -Headers @{ Authorization = "Bearer $token"; Accept = "application/json" }

$response | ConvertTo-Json -Depth 10