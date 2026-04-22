## Plan: Arcadia en AWS con F5 XC

Levantar Arcadia en una EC2 de AWS usando Docker, publicar el acceso por HTTP mediante un HTTP Load Balancer de F5 Distributed Cloud para el dominio arcadia.digitalvs.com, y activar WAAP en modo de monitoreo con API Discovery, API Protection y Bot Defense. La ejecución parte desde cero en el workspace, reutiliza una VPC existente y deja la región de AWS parametrizada. La recomendación es automatizar toda la capa AWS y la mayor cantidad posible de F5 XC con Terraform, pero validar temprano la cobertura del provider Volterra para decidir qué objetos avanzados quedan en Terraform y cuáles en runbook/manual guiado.

**Status**
- Aprobado para handoff a ejecución.
- Este documento es el baseline de implementación.
- La siguiente etapa es crear Terraform para AWS, automatización/base en F5 XC y runbook para cualquier tramo no cubierto por provider o licencia.

**Steps**
1. Fase 1. Descubrimiento de prerequisitos y límites de automatización.
   Verificar credenciales y permisos disponibles para AWS y F5 XC antes de escribir infraestructura: cuenta, VPC y subredes existentes, security groups permitidos, credenciales AWS, tenant URL de F5 XC, credenciales API para Terraform del provider Volterra, licenciamiento y habilitación de WAAP, API Security y Bot Defense, y delegación DNS del host arcadia.digitalvs.com. Esta fase también debe confirmar si Bot Defense Advanced y API Security están habilitados realmente en el tenant.
2. Fase 1. Validar cobertura del provider de F5 XC. Depende del paso 1.
   Probar de forma mínima que el provider Volterra autentica y que soporta, en la versión elegida, los recursos necesarios para al menos HTTP Load Balancer, origin pool, dominio y asociación de seguridad. Si algún objeto avanzado no está cubierto o no es estable, definir desde el principio un split: Terraform para AWS más objetos base de F5, y runbook manual para políticas avanzadas de WAAP, Bot y API.
3. Fase 2. Diseñar la topología de AWS para Arcadia. Depende del paso 1.
   Crear una EC2 Linux en la VPC existente, en subred pública, con IP pública, IAM mínimo, almacenamiento suficiente y un security group restrictivo. Como el acceso será HTTP sólo para laboratorio, la exposición pública del origen debe limitarse al conjunto mínimo necesario.
4. Fase 2. Automatizar el bootstrap de la VM. Puede avanzar en paralelo con el paso 5.
   Preparar Terraform para EC2, variables para región, AMI, tamaño, VPC, subred, key pair y tags. El user_data o cloud-init debe instalar Docker y Docker Compose plugin, clonar el repositorio pupapaik/f5-arcadia o descargar una versión fijada, y desplegar Arcadia como stack reproducible.
5. Fase 2. Adaptar Arcadia a un despliegue reproducible en una sola VM. Puede avanzar en paralelo con el paso 4.
   A partir del repositorio de Arcadia, definir qué contenedores se ejecutarán en la EC2, qué nombres de servicio requiere la aplicación, qué puertos expone cada componente y cuál será el puerto de publicación del frontend. El objetivo es que F5 XC apunte sólo al frontend u origen HTTP expuesto por la VM y que la comunicación interna entre contenedores quede privada en Docker.
6. Fase 3. Preparar la publicación en F5 XC. Depende de los pasos 2, 3, 4 y 5.
   Crear o documentar en Terraform los objetos base de F5: origin pool apuntando a la IP pública o DNS del origen Arcadia, HTTP Load Balancer para arcadia.digitalvs.com, listener HTTP en puerto 80, política de health checks y asociación del dominio. Como el entorno será HTTP sin TLS, debe quedar explícito que no habrá certificado ni redirect a HTTPS.
7. Fase 3. Integrar DNS para arcadia.digitalvs.com. Depende del paso 6.
   Ajustar el registro DNS del host para que apunte al endpoint público que entregue F5 XC. Si el dominio ya está administrado fuera de F5, el plan debe incluir el cambio exacto de registro y TTL de pruebas.
8. Fase 4. Activar seguridad WAAP en modo monitoreo. Depende del paso 6.
   Asociar App Firewall o WAF al HTTP Load Balancer con enforcement en modo monitor o report-only, de forma que no bloquee tráfico inicial. Definir aprendizaje inicial, logging y dashboards a revisar durante la estabilización.
9. Fase 4. Activar API Discovery. Depende de los pasos 5, 6 y 8.
   Habilitar descubrimiento de APIs sobre el tráfico real que atraviese el HTTP Load Balancer para identificar endpoints, métodos y esquemas observados de Arcadia. Esta fase requiere generación de tráfico funcional real.
10. Fase 4. Activar API Protection. Depende del paso 9.
   Una vez descubierto el inventario de endpoints, configurar API Protection sobre los endpoints relevantes de Arcadia, inicialmente en modo no disruptivo o con la acción menos riesgosa disponible en el tenant.
11. Fase 4. Activar Bot Defense. Depende de los pasos 1 y 6.
   Confirmar que la suscripción y roles necesarios estén activos, crear o reutilizar infraestructura y políticas de Bot Defense del tenant y asociarlas al HTTP Load Balancer de Arcadia.
12. Fase 5. Verificación funcional y operativa. Depende de los pasos 4 a 11.
   Validar acceso externo a http://arcadia.digitalvs.com, navegación básica de Arcadia, salud de contenedores, resolución del backend interno de la app, observabilidad en F5 XC, eventos WAF en monitoreo, endpoints descubiertos por API Discovery, asociación de API Protection y telemetría o política de Bot Defense.
13. Fase 5. Documentación operativa y handoff. Depende de todos los pasos anteriores.
   Entregar README o runbook con prerequisitos, variables, orden de ejecución Terraform, secretos requeridos, pasos manuales residuales en F5 XC, validaciones esperadas, riesgos del uso de HTTP y procedimiento para destruir el laboratorio.

**Relevant files**
- /Users/ocarrillo/Labs/pruebas1aq/terraform/aws/providers.tf: providers y versiones de AWS y Volterra/F5 XC.
- /Users/ocarrillo/Labs/pruebas1aq/terraform/aws/variables.tf: variables para región, VPC, subred, instancia, claves, DNS y credenciales no secretas.
- /Users/ocarrillo/Labs/pruebas1aq/terraform/aws/main.tf: red reutilizada, security groups, IAM profile, EC2 e integración de bootstrap.
- /Users/ocarrillo/Labs/pruebas1aq/terraform/aws/user_data.tftpl: instalación de Docker y despliegue reproducible de Arcadia.
- /Users/ocarrillo/Labs/pruebas1aq/terraform/f5xc/main.tf: objetos base de F5 XC, origin pool, HTTP Load Balancer y asociaciones de seguridad soportadas.
- /Users/ocarrillo/Labs/pruebas1aq/terraform/f5xc/variables.tf: tenant URL, namespace, dominios, origen y parámetros de seguridad.
- /Users/ocarrillo/Labs/pruebas1aq/arcadia/docker-compose.yml: stack de contenedores para la app Arcadia en una sola VM.
- /Users/ocarrillo/Labs/pruebas1aq/docs/runbook.md: pasos manuales residuales y validación operativa en F5 XC y DNS.
- /Users/ocarrillo/Labs/pruebas1aq/README.md: guía rápida de despliegue y destrucción del laboratorio.

**Verification**
1. Validar credenciales AWS con identidad efectiva y permisos para EC2, IAM profile, security groups y lookup de VPC o subred.
2. Validar credenciales F5 XC con autenticación real del provider Volterra y una operación mínima de lectura o plan.
3. Ejecutar terraform validate y terraform plan por separado para AWS y F5 XC con la variable de región suministrada por el usuario.
4. Verificar en la EC2 que Docker arranca, que los contenedores de Arcadia quedan en estado healthy y que el frontend responde localmente por HTTP.
5. Verificar desde Internet resolución DNS y respuesta HTTP de arcadia.digitalvs.com a través del HTTP Load Balancer de F5 XC.
6. Generar tráfico funcional de prueba sobre Arcadia y confirmar en F5 XC que el WAF registra eventos en monitor, que API Discovery aprende endpoints y que Bot Defense queda asociado y reportando según la licencia disponible.
7. Ejecutar una prueba negativa simple contra endpoints representativos para observar visibilidad del WAF sin pasar a bloqueo.
8. Documentar cualquier tramo que haya quedado manual por limitaciones reales del provider o del licenciamiento.

**Decisions**
- Incluye una sola VM EC2 pública para laboratorio, no un clúster ni alta disponibilidad.
- Incluye publicación por HTTP únicamente porque fue pedido expresamente para pruebas; no incluye TLS, certificados ni redirect a HTTPS.
- Incluye WAF en modo monitoreo; no incluye enforcement ni bloqueo inicial.
- Incluye activar y dejar operativos API Discovery, API Protection y Bot Defense, pero sujeto a que esas capacidades estén habilitadas en el tenant o licencia.
- La región de AWS queda parametrizada; no se fija en el plan.
- La VPC es existente; el plan no contempla crear una red completa desde cero salvo que en ejecución se detecte que no hay subred pública utilizable.

**Further Considerations**
1. Aunque el laboratorio será HTTP, conviene dejar preparado el Terraform para añadir TLS más adelante sin rediseñar el HTTP Load Balancer.
2. Bot Defense y algunas capacidades de API Security pueden requerir habilitación, licencia, roles o pasos manuales fuera del alcance del provider; por eso la validación temprana del paso 2 no debe posponerse.
3. Publicar el origen con IP pública simplifica el laboratorio, pero expone más superficie que una arquitectura privada con CE o Site. Si el laboratorio evoluciona, conviene migrar a origen privado.

**CI/CD Inputs Confirmed**
- GitHub Actions ejecutará Terraform usando estos secretos: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TFC_TOKEN`, `TFC_ORG`, `XC_API_P12_FILE`, `XC_API_URL`, `XC_P12_PASSWORD` y `SSH_PUBLIC_KEY`.
- GitHub Actions recibirá `AWS_REGION` como variable de entrada para parametrizar el despliegue en AWS.
- `TFC_TOKEN` se usará para autenticar el runner contra Terraform Cloud y `TFC_ORG` para fijar la organización de trabajo.
- `XC_API_P12_FILE` no debe tratarse como una ruta del runner. Debe almacenarse en GitHub como contenido del archivo P12, preferentemente en base64, y reconstruirse durante el workflow en un archivo temporal para el provider de F5 XC.
- `XC_API_URL` y `XC_P12_PASSWORD` alimentarán la autenticación del provider Volterra o F5 XC en el job que ejecute `terraform plan` y `terraform apply`.
- `SSH_PUBLIC_KEY` debe inyectarse en Terraform para crear o asociar el key pair de AWS usado por la EC2 de Arcadia.
- Con este set de secretos y variables ya no es necesario bloquear el diseño esperando OIDC o variables remotas de Terraform Cloud. El flujo recomendado pasa a ser GitHub Actions como ejecutor y Terraform Cloud como backend remoto de estado y locking.

**Implementation Notes For GitHub Actions**
1. El workflow debe exportar `TF_TOKEN_app_terraform_io` a partir de `TFC_TOKEN` para que Terraform autentique contra Terraform Cloud sin pasos interactivos.
2. El workflow debe escribir el secreto `XC_API_P12_FILE` a un archivo temporal, por ejemplo en `.tmp/xc-api-creds.p12`, y pasar esa ruta al provider de F5 XC.
3. El workflow debe mapear `AWS_REGION` a `TF_VAR_aws_region` para mantener una sola fuente de verdad entre CI y Terraform.
4. El workflow debe mapear `SSH_PUBLIC_KEY` a `TF_VAR_ssh_public_key` para que la clave pública quede administrada desde variables de Terraform y no embebida en plantillas.
5. Los secretos de AWS y F5 XC deben existir tanto en el workflow de `plan` como en el de `apply`, pero el job de `apply` debe quedar protegido por environment approval en GitHub.
