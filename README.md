# SEGARANTE API

### Rodando com Docker Compose

#### Clone o repositório
```bash
git clone git@github.com:robmacav/segarante-api.git
```

#### Suba os containers
```bash
docker-compose up -d
```

### Rodando os testes em RSpec via Docker Compose
```bash
docker-compose -f docker-compose.test.yml run --rm test
```
