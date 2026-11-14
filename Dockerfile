# Dockerfile
# Usa una imagen base oficial de Python. Elige una versión específica para consistencia.
FROM python:3.13-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia solo el archivo de dependencias bloqueadas primero para aprovechar el cache de Docker.
# requirements.lock se genera a partir de requirements.txt y fija cada dependencia
# (incluidas las transitivas) con su versión exacta y su hash.
COPY requirements.lock .

# Instala solo las dependencias de ejecución (Flask y Gunicorn).
# --require-hashes: rechaza cualquier paquete cuyo hash no coincida con el bloqueado.
# --only-binary :all: instala solo wheels, sin ejecutar scripts de instalación (setup.py).
# --no-cache-dir reduce el tamaño de la imagen.
RUN pip install --no-cache-dir --only-binary :all: --require-hashes -r requirements.lock

# Copia el código de la aplicación (solo la carpeta app)
COPY app/ ./app/

# Crea un usuario sin privilegios y ejecuta la aplicación con él (no como root)
RUN useradd --create-home --uid 10001 appuser
USER appuser

# Expón el puerto en el que Gunicorn servirá la aplicación
# Gunicorn por defecto usa 8000, así que usaremos ese.
EXPOSE 8000

# Comando para ejecutar la aplicación usando Gunicorn cuando el contenedor inicie
# 'app.app:app' significa: del archivo app.py dentro del paquete app, usa la instancia 'app' de Flask.
# 'workers=4' es un ejemplo, ajusta según sea necesario.
# 'bind 0.0.0.0:8000' es necesario dentro del contenedor para recibir el tráfico del puerto publicado.
CMD ["gunicorn", "--workers=4", "--bind=0.0.0.0:8000", "app.app:app"]
