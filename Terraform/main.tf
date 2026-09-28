#Criação da minha EC2
resource "aws_instance" "instancia" {
  ami                         = "ami-01c265752adadcdf8"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.publica.id
  tags = {
    Name = "Vinicius-mapleStorage"
  }

  user_data = templatefile("${path.module}/scripts/install.sh", {

    app_port = 8080

    rds_endpoint = aws_db_instance.rds_db.address

    rds_database = "mapleStorage"

    rds_username = "admin"

    rds_password = var.db_senha

  })
  vpc_security_group_ids = [aws_security_group.SG.id]
}

resource "aws_db_instance" "rds_db" {
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "mapleStorage"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = var.db_senha
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.rds_subredes.name
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.SGPriv.id]

  tags = {
    Name = "Vinicius mapleStorageRds"
  }
}

resource "aws_db_subnet_group" "rds_subredes" {
  name = "maplestorage-rds-grupo-subrede"
  subnet_ids = [
    aws_subnet.privada.id,
    aws_subnet.privada2.id
  ]
  tags = {
    Name = "Vinicius MapleStory RDS grupo subredes"
  }

}
#Security group do lamba
resource "aws_security_group" "lambda_sg" {

  name        = "maple-storage-lambda-sg"
  description = "Security Group da Lambda para acesso ao RDS"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Permitir saida da Lambda"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Vinicius MapleStorage-Lambda-SG"
  }
}
#Meu security Group
resource "aws_security_group" "SG" {
  name        = "AprovarTrafego"
  description = "Todo o trafego para a aplicacao"
  vpc_id      = aws_vpc.main.id
  #liberado para toda a internet na porta 80, HTTP
  ingress {
    description = "Liberar a entrada para toda a internet na porta 80, HTTP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
  ingress {
    description = "Node.js"

    from_port = 8080

    to_port = 8080

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberar a entrada para toda a internet na porta 443, HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }
  ingress {
    description = "protocolo ssh"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22

  }
  egress {
    description = "Liberar a saida da aplicacao"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "SGPriv" {
  name        = "SgPrivada"
  description = "Sg para o trafego privado no meu RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Liberado o acesso para a instancia dentro da vpc"
    #cidr_block = ["aws_vpc.main.cidr_block"]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.SG.id]
  }
  ingress {
    description     = "Liberar o acesso para a lambda acessar o RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
  egress {
    description = "Permitir saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
#Criação da minha VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Vinicius maplestorageMain"
  }
}
#Criação do meu gateway de acesso a internet
resource "aws_internet_gateway" "mainGateway" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Vinicius mapleStorageMainGateway"
  }
}

#Criação da minha tabela de rotas
resource "aws_route_table" "route_table_publica" {
  vpc_id = aws_vpc.main.id
  #Essa route aponta para toda a internet 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mainGateway.id
  }
  tags = {
    Name = "Vinicius mapleStorageRouteTablePublica"
  }
}

resource "aws_route_table" "route_table_privada" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Vinicius mapleStorageRouteTablePriv"
  }

}
#Minha subrede publica
resource "aws_subnet" "publica" {
  cidr_block        = "10.0.1.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-2a"
  tags = {
    Name = "Vinicius mapleStorageSubRedePub"
  }
}
#Associa a minha subrede a uma rota criada no route table
#Obs:A subnet irá usar todas as rotas da route table, mas irá associar a
#que mais faz sentido pra ela, por exemplo:
resource "aws_route_table_association" "associacaoPublica" {
  subnet_id      = aws_subnet.publica.id
  route_table_id = aws_route_table.route_table_publica.id
}

#Minha subrede privada
resource "aws_subnet" "privada" {
  cidr_block        = "10.0.2.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-2a"
  tags = {
    Name = "Vinicius mapleStorageSubRedePriv"
  }
}
resource "aws_subnet" "privada2" {
  cidr_block        = "10.0.3.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-2b"

  tags = {
    Name = "Vinicius mapleStorageSubRedePriv2"
  }
}
resource "aws_route_table_association" "associationPrivada" {
  subnet_id      = aws_subnet.privada.id
  route_table_id = aws_route_table.route_table_privada.id
}
resource "aws_route_table_association" "associationPrivada2" {
  subnet_id      = aws_subnet.privada2.id
  route_table_id = aws_route_table.route_table_privada.id
}


