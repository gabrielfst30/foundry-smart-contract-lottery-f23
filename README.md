# 🎰 Lottery / Raffle Smart Contract (Foundry)

Este repositório contem um contrato inteligente de sorteio (lottery / raffle) desenvolvido com Foundry, utilizando o serviço VRF (Verifiable Random Function) da Chainlink para garantir aleatoriedade segura. Usuários pagam para entrar no sorteio e um vencedor é escolhido de forma imparcial.

# 🚀 Tecnologias e Ferramentas

Solidity 0.8.x — Smart contracts na EVM

Foundry — Forge, Anvil etc., para desenvolvimento, testagem e deploy rápido

Chainlink VRF — Para aleatoriedade criptograficamente verificável

Forge scripts & tests — Automação de deploy e validações com mocks/localchain

# 🔧 Funcionalidades Principais

Participantes podem entrar no sorteio ao pagar uma taxa pré-definida

Estado do contrato gerencia se o sorteio está OPEN ou em PROCESSO de cálculo

Uso de Chainlink VRF para solicitar um número aleatório seguro

Seleção do vencedor baseada nesse número aleatório

Proprietário do contrato (“owner”) pode iniciar o sorteio / finalizar processo

# 📁 Estrutura do Projeto
foundry-smart-contract-lottery-f23/
├── src/
│   └── Lottery.sol            # Contrato principal de sorteio
├── script/
│   └── DeployLottery.s.sol    # Script de deploy usando Foundry
├── test/
│   └── LotteryTest.t.sol      # Testes do contrato
├── lib/                       # Dependências externas (via forge install)
├── foundry.toml               # Configuração do Foundry
├── .gitignore
└── README.md

# 🧪 Como Rodar Localmente / Testar
Pré-requisitos

Instalar Foundry (Forge, Anvil)

Ambiente com Solidity compatível

Passos
# Clone o repositório
git clone https://github.com/gabrielfst30/foundry-smart-contract-lottery-f23.git
cd foundry-smart-contract-lottery-f23

# Instale dependências e libs
forge install

# Compile os contratos
forge build

# Execute os testes
forge test

🌐 Deploy / Uso com Chainlink VRF

Para usar o contrato de verdade com Chainlink VRF, vai precisar:

Subscription ID ativo da Chainlink VRF

Endereço do coordinator VRF na rede que vai usar

Gas lane / keyHash correto

Configurar limite de gas para callback (callbackGasLimit)

Deploy com parâmetros adequados

Exemplo de comando (ajusta conforme rede):

forge script script/DeployLottery.s.sol:DeployLottery \
  --rpc-url <URL_DA_REDE> \
  --private-key <SUA_CHAVE_PRIVADA> \
  --broadcast

⚠️ Boas Práticas & Considerações

Validar se há participantes suficientes antes de chamar a função de sorteio

Certificar que o contrato possui fundos de LINK (ou recurso que o VRF use) se necessário

Controlar bem o estado interno (ex: OPEN / CALCULATING) para evitar reset ou entradas indevidas

Usar eventos para registrar quando o sorteio é iniciado, random number requisitado e vencedor escolhido — facilita auditoria

👤 Autor

Desenvolvido por Gabriel Santa Ritta — Fullstack / Blockchain Developer dedicado a construir contratos inteligentes seguros, auditáveis e eficientes.
