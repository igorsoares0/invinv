# MVP - App de Faturamento com Flutter e SQLite

## Visão Geral
Um aplicativo móvel para criação, envio e gerenciamento de faturas profissionais, inspirado no Invoice Simple. O foco é simplicidade, praticidade e profissionalismo para pequenas empresas e freelancers.

## Funcionalidades Essenciais do MVP

### 1. Gerenciamento de Dados Básicos

#### Clientes
- **CRUD de clientes** (Create, Read, Update, Delete)
  - Nome da empresa/pessoa
  - Email (obrigatório)
  - Telefone
  - Endereço completo
  - Observações
- **Importação de contatos** do telefone
- **Busca e filtros** por nome/empresa
- **Histórico de faturas** por cliente

#### Produtos/Serviços
- **CRUD de itens faturáveis**
  - Nome do produto/serviço
  - Descrição
  - Preço unitário
  - Unidade de medida (hora, peça, kg, etc.)
  - Categoria (opcional)
- **Reutilização** de itens em novas faturas
- **Busca rápida** durante criação de faturas

### 2. Criação de Documentos

#### Faturas (Invoices)
- **Criação simples e intuitiva**
  - Seleção de cliente
  - Adição de múltiplos itens
  - Cálculo automático de subtotais
  - Aplicação de descontos (% ou valor fixo)
  - Cálculo de impostos configuráveis
  - Total final automático
- **Numeração automática** e sequencial
- **Data de emissão e vencimento**
- **Status da fatura** (Rascunho, Enviada, Paga, Vencida)
- **Observações e termos** personalizáveis

#### Orçamentos (Estimates)
- **Mesma interface** das faturas
- **Conversão para fatura** com um clique
- **Validade do orçamento**
- **Status específicos** (Pendente, Aprovado, Rejeitado)

#### Recibos
- **Criação para pagamentos recebidos**
- **Vinculação com faturas**
- **Diferentes formas de pagamento**

### 3. Personalização e Branding

#### Configurações da Empresa
- **Dados da empresa**
  - Nome e razão social
  - Logo (upload e redimensionamento)
  - Endereço completo
  - Telefone e email
  - Website
  - CNPJ/CPF
- **Configurações fiscais**
  - Tipos de impostos padrão
  - Mensagens padrão
  - Termos e condições

#### Templates
- **2-3 templates profissionais** básicos
- **Cores personalizáveis**
- **Posicionamento do logo**
- **Preview em tempo real**

### 4. Geração e Compartilhamento

#### Exportação PDF
- **Geração de PDF** com qualidade profissional
- **Layout responsivo** para diferentes tamanhos
- **Fontes legíveis** e design limpo
- **Logo em alta resolução**

#### Compartilhamento
- **Email direto** do app
- **WhatsApp Business**
- **Compartilhamento via sistema** (outras redes sociais)
- **Salvamento na galeria**
- **Impressão** (se disponível)

### 5. Controle Financeiro Básico

#### Dashboard
- **Resumo do mês atual**
  - Total faturado
  - Faturas pendentes
  - Faturas vencidas
  - Faturas pagas
- **Gráficos simples**
  - Faturamento mensal
  - Status das faturas
- **Indicadores visuais** de performance

#### Relatórios Básicos
- **Lista de faturas** por período
- **Relatório por cliente**
- **Exportação para CSV/Excel**
- **Filtros por data, cliente, status**

### 6. Funcionalidades de Produtividade

#### Busca e Filtros
- **Busca global** (clientes, faturas, produtos)
- **Filtros avançados** por data, status, valor
- **Ordenação** por diferentes critérios
- **Favoritos** para acesso rápido

#### Automações Básicas
- **Numeração sequencial** automática
- **Cálculos automáticos** de impostos
- **Preenchimento automático** de dados recorrentes
- **Lembretes** de faturas vencendo (notificações push)

## Estrutura do Banco de Dados (SQLite)

### Tabelas Principais

```sql
-- Configurações da empresa
companies (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  legal_name TEXT,
  logo_path TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  tax_id TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)

-- Clientes
clients (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)

-- Produtos/Serviços
products (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  unit TEXT DEFAULT 'un',
  category TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)

-- Faturas
invoices (
  id INTEGER PRIMARY KEY,
  number TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL, -- 'invoice', 'estimate', 'receipt'
  client_id INTEGER NOT NULL,
  issue_date DATE NOT NULL,
  due_date DATE,
  status TEXT DEFAULT 'draft', -- 'draft', 'sent', 'paid', 'overdue'
  subtotal DECIMAL(10,2) NOT NULL,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  tax_amount DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  notes TEXT,
  terms TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES clients (id)
)

-- Itens da fatura
invoice_items (
  id INTEGER PRIMARY KEY,
  invoice_id INTEGER NOT NULL,
  product_id INTEGER,
  description TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
```

## Arquitetura do App Flutter

### Estrutura de Pastas
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes/
├── core/
│   ├── database/
│   ├── utils/
│   └── constants/
├── features/
│   ├── clients/
│   ├── products/
│   ├── invoices/
│   ├── dashboard/
│   └── settings/
└── shared/
    ├── widgets/
    ├── models/
    └── services/
```

### Tecnologias e Dependências

#### Essenciais
- **flutter**: Framework principal
- **sqflite**: Banco de dados SQLite
- **path**: Gerenciamento de caminhos
- **pdf**: Geração de PDFs
- **printing**: Impressão e compartilhamento de PDFs
- **image_picker**: Upload de logo e imagens
- **shared_preferences**: Configurações locais

#### Interface
- **flutter_bloc** ou **provider**: Gerenciamento de estado
- **go_router**: Navegação
- **flutter_form_builder**: Formulários
- **intl**: Formatação de datas e números
- **flutter_screenutil**: Responsividade

#### Funcionalidades
- **url_launcher**: Abrir email/WhatsApp
- **share_plus**: Compartilhamento
- **contacts_service**: Importar contatos
- **local_notifications**: Notificações push
- **permission_handler**: Permissões do sistema

## Fluxo do Usuário (MVP)

### Primeira Utilização
1. **Onboarding simples** (3 telas máximo)
2. **Configuração básica da empresa**
3. **Tutorial rápido** das principais funções

### Fluxo Principal
1. **Dashboard** com resumo e acesso rápido
2. **Nova fatura**: Cliente → Itens → Revisão → Envio
3. **Gestão**: Clientes e Produtos pré-cadastrados
4. **Relatórios**: Acompanhamento básico

### Casos de Uso Críticos
- **Criar fatura em menos de 2 minutos**
- **Enviar por email/WhatsApp instantaneamente**
- **Acessar histórico rapidamente**
- **Funcionar 100% offline**

## Critérios de Sucesso do MVP

### Funcionalidade
- ✅ Criar, editar e enviar faturas profissionais
- ✅ Gerenciar clientes e produtos
- ✅ Gerar PDFs com qualidade
- ✅ Funcionar offline completamente
- ✅ Interface intuitiva e rápida

### Performance
- ✅ App inicia em menos de 3 segundos
- ✅ Geração de PDF em menos de 5 segundos
- ✅ Busca instantânea
- ✅ Sincronização local rápida

### Experiência
- ✅ Onboarding em menos de 5 minutos
- ✅ Criar primeira fatura em menos de 3 minutos
- ✅ Design profissional e moderno
- ✅ Zero bugs críticos

## Roadmap Futuro (Pós-MVP)

### Versão 1.1
- **Backup na nuvem** (Google Drive/iCloud)
- **Faturas recorrentes**
- **Mais templates**
- **Assinatura digital**

### Versão 1.2
- **Integração com gateways de pagamento**
- **Relatórios avançados**
- **Multi-empresa**
- **Sincronização entre dispositivos**

### Versão 2.0
- **Versão web**
- **API para integrações**
- **App para clientes**
- **Funcionalidades de estoque**

## Considerações Técnicas

### Otimização SQLite
- **Índices** nas queries mais frequentes
- **Transações** para operações múltiplas
- **Backup incremental** dos dados
- **Compressão** de imagens

### Performance Flutter
- **Lazy loading** de listas grandes
- **Debounce** em campos de busca
- **Cache** de imagens e PDFs
- **Otimização** de rebuilds desnecessários

### Segurança
- **Validação** rigorosa de inputs
- **Sanitização** de dados exportados
- **Criptografia** de dados sensíveis
- **Backup seguro** das informações