# Terraform AWS Odoo Deployment

Este proyecto utiliza **Terraform** para desplegar una instancia de **Odoo** en **AWS EC2** usando **Docker** con **PostgreSQL** como base de datos.

## Características

- Despliegue automatizado de Odoo en AWS EC2 con Docker
- Configuración automática de PostgreSQL como base de datos
- Instalación y configuración de Docker en la instancia Ubuntu
- Configuración de grupos de seguridad para puertos 22 (SSH), 80 (HTTP), 443 (HTTPS) y 8069 (Odoo)
- Volúmenes persistentes para datos de Odoo y PostgreSQL
- Script de instalación automatizado para Docker y Odoo

## Arquitectura

```
AWS EC2 Instance (Ubuntu)
├── Docker Engine
├── Odoo Container (Puerto 8069)
├── PostgreSQL Container
└── Volúmenes Persistentes
    ├── odoo_data
    └── postgres_data
```

## Requisitos

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- Cuenta de AWS con credenciales configuradas
- Par de claves SSH en AWS EC2
- Acceso a internet para descargar imágenes Docker

## Configuración

### 1. Variables de Entorno

Crea un archivo `terraform.tfvars` con tus configuraciones:

```hcl
aws_region = "us-east-1"
instance_type = "t3.medium"
key_name = "tu-clave-ssh"
odoo_version = "16.0"
```

### 2. Configuración de AWS

Asegúrate de tener configuradas tus credenciales de AWS:

```bash
export AWS_ACCESS_KEY_ID="tu-access-key"
export AWS_SECRET_ACCESS_KEY="tu-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

## Uso

### 1. Clona el repositorio

```bash
git clone https://github.com/tu_usuario/terraform-aws-odoo.git
cd terraform-aws-odoo
```

### 2. Inicializa Terraform

```bash
terraform init
```

### 3. Revisa el plan de despliegue

```bash
terraform plan
```

### 4. Aplica la infraestructura

```bash
terraform apply
```

### 5. Accede a Odoo

Una vez completado el despliegue, accede a Odoo usando:

- **URL**: `http://IP_PUBLICA_EC2:8069`
- **Puerto**: 8069 (configurado en el grupo de seguridad)

## Variables Principales

| Variable        | Descripción                   | Valor por defecto |
| --------------- | ----------------------------- | ----------------- |
| `aws_region`    | Región de AWS                 | `us-east-1`       |
| `instance_type` | Tipo de instancia EC2         | `t3.medium`       |
| `key_name`      | Nombre de la clave SSH en AWS | -                 |
| `odoo_version`  | Versión de Odoo               | `16.0`            |
| `vpc_cidr`      | CIDR del VPC                  | `10.0.0.0/16`     |
| `subnet_cidr`   | CIDR de la subred             | `10.0.1.0/24`     |

## Grupos de Seguridad

El proyecto configura automáticamente los siguientes puertos:

- **22**: SSH
- **80**: HTTP
- **443**: HTTPS
- **8069**: Odoo

## Estructura del Proyecto

```
terraform-aws-odoo/
├── main.tf              # Configuración principal de Terraform
├── variables.tf         # Definición de variables
├── terraform.tfvars     # Valores de variables (no commitear)
├── setup_nginx_ssl.sh   # Script de instalación de Docker y Odoo
├── .gitignore          # Archivos a ignorar en Git
└── README.md           # Este archivo
```

## Gestión de la Base de Datos

### Inicialización Manual (si es necesario)

Si Odoo muestra errores de base de datos, conéctate a la instancia y ejecuta:

```bash
# Conectarse a la instancia
ssh -i tu-clave.pem ubuntu@IP_PUBLICA

# Verificar contenedores
docker ps

# Reiniciar contenedores si es necesario
docker-compose down
docker-compose up -d
```

## Monitoreo y Logs

### Ver logs de Odoo

```bash
ssh -i tu-clave.pem ubuntu@IP_PUBLICA
docker logs odoo
```

### Ver logs de PostgreSQL

```bash
docker logs postgres
```

## Escalabilidad y CI/CD

### Para múltiples instancias

El proyecto está diseñado para escalar a múltiples sitios:

1. **Backup de base de datos**: Scripts de respaldo automático
2. **Volúmenes persistentes**: Datos preservados entre reinicios
3. **Configuración centralizada**: Variables de Terraform para múltiples entornos

### CI/CD Recomendado

- **GitHub Actions** para build y deploy automático
- **Docker Hub** para imágenes personalizadas de Odoo
- **Scripts de sincronización** para múltiples sitios

## Solución de Problemas

### Error de Acceso Denegado

Si obtienes "access denied" al acceder a Odoo:

1. Verifica que el puerto 8069 esté abierto en el grupo de seguridad
2. Confirma que los contenedores estén ejecutándose: `docker ps`
3. Revisa los logs: `docker logs odoo`

### Error de Base de Datos

Si Odoo muestra errores de base de datos:

1. Reinicia los contenedores: `docker-compose restart`
2. Verifica la conectividad de PostgreSQL
3. Inicializa manualmente la base de datos si es necesario

## Limpieza

Para destruir toda la infraestructura creada:

```bash
terraform destroy
```

**⚠️ Advertencia**: Esto eliminará todos los datos de Odoo y PostgreSQL. Haz backup antes de ejecutar este comando.

## Archivos Sensibles

Los siguientes archivos están incluidos en `.gitignore`:

- `terraform.tfvars` (contiene credenciales)
- `*.tfstate` (estado de Terraform)
- `.ssh/` (claves SSH)
- `.terraform/` (archivos de Terraform)

## Licencia

MIT

## Contribuciones

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request
