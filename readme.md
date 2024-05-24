# Projeto Cloud 


## Índice

 [Projeto Cloud](#projeto-cloud)
   - [Introdução](#introdução)
   - [A aplicação](#a-aplicação)
   - [Resumo Arquitetura](#resumo-arquitetura)
   - [Requisitos para execução](#requisitos-para-execução)
   - [Instruções de uso](#instruções-de-uso)
     - [Deploy através de script de conveniência](#deploy-através-de-script-de-conveniência)
     - [Deploy manual](#deploy-manual)
     - [Deletar Stack](#deletar-stack)
   - [Testando a aplicação](#testando-a-aplicação)
   - [Teste rápido de AutoScaling](#teste-rápido-de-autoscaling)
   - [Arquitetura](#arquitetura)
     - [Diagrama de arquitetura](#diagrama-de-arquitetura)
     - [VPC](#vpc)
     - [Subnets](#subnets)
     - [EC2](#ec2)
     - [AutoScaling](#autoscaling)
     - [Application Load Balancer](#application-load-balancer)
     - [Security Groups](#security-groups)
     - [DynamoDB](#dynamodb)
   - [Custo](#custo)
     - [Premissas](#premissas)
     - [Cálculo](#cálculo)
     - [Custo por teste de carga](#custo-por-teste-de-carga)
   - [Teste de Carga](#teste-de-carga)
     - [Executando o teste de carga](#executando-o-teste-de-carga)

Você pode adicionar este índice ao início do seu arquivo markdown para facilitar a navegação com links funcionando corretamente.
## Introducao
Este é um projeto de deploy de uma aplicaçao em infraestutura na aws atraves de CloudFormation. 

## A aplicação
A aplicação é um software open source criado pela própria AWS como demonstração de uso do DynamoDB. É um jogo da velha multiplayer onde o login é feito apenas por nome (sem senha). Um jogador pode convidar outro jogador por nome para um jogo. Ao aceitar uma partida, o estado do jogo é sempre guardado no DynamoDB. O histórico de jogos de cada jogador é mantido em um banco de dados.


## Resumo Arquitetura

A aplicação é executada dentro de instancias de ec2 com auto scaling baseado em numero de request por target. OS requests são distribuidos as instancias através de um Application Load Balancer. O banco de dados utilizados é o dynamodb. Ele esta sem ip publico, porem os ec2 conseguem acessalo devidos a um role do IAM.


## Requisitos para execução
 - Necessário ter AWS CLI instalada e autenticada
 - Permissões necessárias no IAM
 - Necessário ter AWS CLI configurada com região padrão us-east-1 (execute `aws configure` e pressione Enter para manter as configurações anteriores, exceto a região padrão que deve ser alterada para us-east-1)
 - Para utilizar scripts de conveniência, é necessário usar sistema operacional Linux

## Instruções de uso
### Deploy através de script de conveniência
1. Clone este repositorio
		
		git clone https://github.com/arieltl/ProjetoCloudFormation
1. Entre no diretorio do projeto

		cd ProjetoCloudFormation
1. Execute o script de conveniência deploy
    ```
	sudo chmod +x deploy.sh
	```
	```
    ./deploy.sh <stackname>
    ```
 4. Aguarde o deploy terminar, ao fim do deploy sera exibido automaticamente o dns do load balancer, use ele para acessar a aplicação.

	#### Configurando parametros de AutoScaling
	Use o script deploy passando os parametros desejados, exemplo:
	```bash
	./deploy.sh myStack "ParameterKey=HighThreshold,ParameterValue=1000 ParameterKey=LowThreshold,ParameterValue=3000"  
	```

	Os parametros HighThreshold e LowThreshold são os valores de requests por target que acionam os alarmes de auto scaling. O HighThreshold é o valor de requests por target que aciona o alarme de aumento de instancias, o LowThreshold é o valor de requests por target que aciona o alarme de diminuição de instancias. Importante notar que o High Threshold é avaliado em um periodo diferente do low threshold, por isso o exemplo acima usa um numero maior para o low threshold. Leia mais sobre isso na seção de [AutoScaling](#autoscaling).
### Deploy manual
1. Siga os passos 1 e 2 do tópico anterior
2. Execute o comando abaixo para criar a stack (omita os parâmetros caso deseje utilizar os valores padrão)
	```
	aws cloudformation create-stack \                                                      
	--stack-name <stackname> \
	--template-body file://projeto.yaml --capabilities CAPABILITY_IAM \
	--parameters ParameterKey=HighThreshold,ParameterValue=<value> ParameterKey=LowThreshold,ParameterValue=<value>
	```
3. Aguarde o deploy terminar, para ter certeza que o deploy foi bem sucedido, verifique o aws console
4. Após o fim do deploy, execute o comando abaixo para obter o DNS do Load Balancer ou acesse o console da AWS e verifique o output da stack
	```
	 aws cloudformation describe-stacks --stack-name <stackname> --query "Stacks[0].Outputs" 
	```
### Deletar Stack
 - Para deletar a stack sem deletar a tabela do dynamodb, execute o comando

		aws cloudformation delete-stack --stack-name <stackname>
 - Para deletar a stack e a tabela do dynamodb, execute o script de conveniência destroy
	```
	 sudo chmod +x destroy.sh
	```
	```
	 ./destroy.sh <stackname>
	```

## Testando a aplicação
1. Acesse o DNS do Load Balancer exibido ao final do deploy
1. No canto superior direito, utilize o campo de texto para inserir o nome do jogador e clique em "Login"
1. Clique em em Create para criar um novo jogo
1. Insira o nome do jogador que deseja convidar para jogar e clique em "Create Game"
1. Abra em outro navegador ou em uma aba anônima e faça login com nome do jogador convidado, haverá um convite pendente listado
1. O convite estará armazenado no DynamoDB, ele será exibido por tempo ilimitado até que seja aceito ou recusado
1. Clique em "Accept" para aceitar o convite
1. Jogue e divirta-se!
1. Você pode sair e retornar ao jogo a qualquer momento, o estado do jogo será mantido no DynamoDB
1. Ao fim do jogo retorne para a tela inicial, o jogo ficará salvo no histórico dos jogadores

## Teste rapido de AutoScaling
1. Execute o comando abaixo para gerar requests para o Load Balancer
	```
	./test.sh <dns> <num_requests>
	```
1. Caso num request seja omitido, o script irá gerar 20 requests que é o suficiente para acionar o alarme caso os parametros padrão sejam utilizados

## Arqiutetura
### Diagrama de arquitetura
![Arquitetura](arquitetura.png)

### VPC
Foi criada uma VPC para o projeto utilizando o bloco de IP `10.0.0.0/16`. 

### Subnets
Foram criadas 2 subnets privadas em zonas de disponibilidade diferentes. As subnets foram criadas com os blocos de IP `10.0.0.0/24` e `10.0.1.0/24`. A necessidade de criar 2 subnets privadas é para garantir alta disponibilidade da aplicação e é uma exigência do Application Load Balancer.

### EC2
Foram criadas instâncias EC2 com uma AMI customizada gerada a partir do Ubuntu. A AMI ja conta com a aplicação instalada e configurada, e uma unit file para iniciar a aplicação atraves do systemd. Foi utilizado o UserData para rodar um script python inicial e em seguida inicar o serviço da aplicação. A necessidade do script inicial é explicada na seção do [DynamoDB](#dynamodb).


### AutoScaling
Foi criado um AutoScaling Group para garantir alta disponibilidade da aplicação. O AutoScaling Group foi configurado para escalar o número de instâncias baseado no número de requests por target. O AutoScaling Group foi configurado para ter no mínimo 1 instâncias e no máximo 5 instâncias. Foram criados 2 alarmes cloudwatch que executam Scaling Policies para aumentar e diminuir o número de instâncias baseado no número de requests por target. O alarme de aumento de instâncias é acionado quando o número de requests por target é maior que o parametro de High em 1 dos ultimos 6 pontos de dados, cada ponto de dado corresponde a requests por 10 segundos. O alarme de diminuição de instâncias é acionado quando o número de requests por target é menor que o parametro de Low em 1 dos ultimos 2 pontos de dados, cada ponto de dado corresponde a requests por 60 segundos. Existe um cooldown de 65 segundos para evitar que o AutoScaling Group aumente e diminua o número de instâncias muito rapidamente.

Existe uma diferença entre o periodo avaliado para aumentar ou diminuir o numero de instancias, isso foi feito para que o auto scaling respondesse mais rapidamente a um aumento de requests do que a uma diminuição de requests. A metrica de Requests por Target é atulizada a cada 60 segundos, porem ela separa corretamente os datapoints de 10 segundos. Caso fosse feito um alarm de um datapoint de 60 segundos, para um numero x de requests, o auto scaling so iria aumentar o numero de instancias apos 60 segundos de requests acima de x, o autoscaling não responderia a um pico rapido de (x/6)+1 requests, ja com um alarma de um datapoint em 6 de 10 segundos para x/6 requests, o mesmo pico causa o aumento de instancias.


### Application Load Balancer
O Application Load Balancer ouve na porta 80 e distribui os requests entre as instâncias do AutoScaling Group na porta 5000.

### Security Groups
Foram criados Security Groups para as instâncias EC2 e para o Application Load Balancer. O Security Group das instâncias EC2 permite tráfego de entrada na porta 5000 apenas do Security Group do Application Load Balancer. O Security Group do Application Load Balancer permite tráfego de entrada na porta 80 de qualquer IP.

### DynamoDB
A tabela do DynamoDB é criada pela aplicação e não é criada pelo CloudFormation. Isso permite que o resto da Infraestrutura seja destroida e recriada sem perder os dados da aplicação. A aplicação é em python2 usando a biblioteca boto para acessar o DynamoDB. O boto não permite criação de tabelas On-Demand, apenas provisionadas. Para que fosse possivel lidar melhor com picos de trafego foi criado um script em python3 que cria a tabela caso ela não exista usando boto3, que permita tabelas On-Demand.

Para que a aplicação consiga acessar o DynamoDB foi criado um role no IAM que permite acesso a tabela do DynamoDB. O role foi anexado as instancias EC2.



## Custo

### Premissas

Considerando que a aplicação é um jogo da velha multiplayer, é esperado que o número de jogadores seja muito baixo a maior parte do tempo. Porem situações átipicas como um dia chuvoso que é feriado ou um streamer popular jogando o jogo podem causar um pico de jogadores. Como seria dificil prever um bom valor para o trafego normal, optei por ser pessimista considerando picos muito mais frequentes do que o normal, dessa maneira caso seja possivel lidar com o worst case scenario, o custo para o uso normal não deverá causar problemas orçamentarios.

Foi considerado que serão jogados entre 2 a 4 mil jogos por dia. Sendo que esse jogos concetrados num periodo pequeno de tempo de modo que a maior parte do dia apenas uma instancia estará rodando e durante 30 minutos por dia, 3 instancias estarão rodando. Cada jogo tem tamanho no dynamo de cerca de 0.5kb e cada load de pagina tem cerca de 4kb. Considerando os altos periodo de inatividade foi usado em media apenas 1 ip publico e uma media de 10 requests por segundo ao load balancer (o que é uma media pessimista mesmo considerando o tempo de baixo trafego). Foi considerado que o DynamoDB ja tem 10gb de dados armazenados.

### Calculo
Baseado nessas premissas a calculadora de custo da AWS estima um custo de U$35.84 por mes.
![Custo](custo.png)

### Custo por teste de carga
O custo no dia em que foi feito o [teste de carga](#teste-de-carga) foi de U$1.43, valor um pouco acima do calculado, porem a quantidade de requests feitas são equivalente a cerca de 8 a 10 mil jogos no dia, o que é acima do valor usado para os calculos. Portanto o custo do teste de carga foi considerado compativel com o calculado.
O custo de worst case scneario pode ser então estimado como cerca de U$40,00 por mes.



## Teste de Carga
![Teste de carga](load_test.png)
Foi feito um teste com locust de 5 minutos com 1500 usuarios virtuais, cada usuario fazendo um request a cada 5 a 20 segundos. Logo em seguida foi feito um teste de 10 minutos com 2000 usuarios. Em seguida esse teste foi extendido por mais cerca de 5 minutos para aguardar a estabilização do auto scaling.

Os valores dos parametros da stack foram escolhidos baseados em testes previos para garantir que o auto scaling estabilizasse em 5 maquinas. Permitindo ver se o uso de CPU estava numa faixa aceitavel e, por tanto, se 5 maquinas eram suficientes para o pico de trafego.

O pico de uso de CPU antes da estabilização do auto scaling foi de cerca de 65%, o que é um valor aceitavel. Apos a estabilização o uso de CPU nas 5 instancias foi de 30 a 40%, o que é um valor muito bom. Isso indica que o auto scaling foi capaz de responder rapidamente ao aumento de trafego e que o numero de instancias foi suficiente para lidar com o pico de trafego, e mesmo não podendo escalar para 6 instancias, essas 5 instancias ainda poderiam lidar com mais trafego.

### Executanto o teste de carga
1. crie um ambiente virtual python
2. Instale as dependencias
	```
	pip install -r requirements.txt
	```
3. Execute o locust dentro do diretorio deste repositorio
	```
	locust
	```
4. Acesse o URL exibido no terminal e cole o DNS do Load Balancer.
5. Configure o numero de usuarios virtuais e o tempo desejado e inicie o teste.