# Currency Converter

API de conversión de monedas que usa como intermediarias las criptomonedas disponibles en Buda.com.

## Supuestos

-  Sobre el precio de conversión: en la parte de los requerimientos entendí que había que usar el libro de órdenes de Buda, pero en la parte de los supuestos decía explícitamente que había que usar el precio de la última transacción, así que opté por lo último.

## Requisitos

- Docker (recomendado) o Ruby 3.2 instalado

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/nicolasguridi/currency-converter.git
cd currency-converter
```

2. Preparar el entorno:
```bash
# Usando Docker (recomendado)
docker build -t currency-converter .
```

```bash
# Sin Docker (requiere Ruby y Bundler instalados)
bundle install
```

3. Ejecutar la aplicación:
```bash
# Usando Docker (recomendado)
docker run -p 4567:4567 currency-converter
```

```bash
# Sin Docker (requiere Ruby y Bundler instalados)
bundle exec rackup -o 0.0.0.0 -p 4567
```

## Documentación de la API

### Convertir monedas

Convierte una cantidad de una moneda a otra utilizando criptomonedas como intermediario.

**Endpoint:** `GET /convert`

**URL Base:** `http://localhost:4567`

#### Parámetros de la llamada

| Parámetro      | Tipo   | Requerido | Descripción                    |
|----------------|--------|-----------|--------------------------------|
| from_currency  | string | Sí        | Moneda de origen (CLP/PEN/COP) |
| to_currency    | string | Sí        | Moneda destino (CLP/PEN/COP)   |
| amount         | number | Sí        | Cantidad a convertir           |

#### Ejemplo de llamada

```bash
curl "http://localhost:4567/convert?from_currency=CLP&to_currency=PEN&amount=10000"
```

#### Ejemplo de respuesta exitosa

```json
{
  "success": true,
  "from_currency": "CLP",
  "to_currency": "PEN",
  "original_amount": 10000,
  "converted_amount": 123.45,
  "intermediary_crypto": "BTC"
}
```

## Testing

Para correr los tests:

```bash
# Usando Docker (recomendado)
docker build -t currency-converter . && docker run currency-converter rspec
```

```bash
# Sin Docker (requiere Ruby y Bundler instalados)
bundle install && bundle exec rspec
```
