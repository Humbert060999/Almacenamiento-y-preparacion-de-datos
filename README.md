# Almacenamiento-y-preparacion-de-datos
Diplomado en Ciencias de Datos

INTEGRANTES:
- Humberto Lucana Mamani
- Michelle Quispe Choque

# Descripción del Proyecto

El proyecto consiste en el diseño e implementación de una base de datos transaccional (OLTP) y un Data Warehouse utilizando SQL Server basado en el caso de estudio de la base de datos NorthWind.

La base de datos permite trabajar con información relacionada a ventas de productos alimenticios a clientes (empresas y particulares) en múltiples países.

El objetivo principal es construir una arquitectura completa para análisis de datos, integrando:

- Base de datos OLTP
- Modelo dimensional tipo estrella
- Procesos ETL
- SQL Server Integration Services (SSIS)
- Visual Studio Community

Esto permitirá almacenar información transaccional y posteriormente transformarla en información analítica para reportes y toma de decisiones.

---

# Tecnologías Utilizadas

- SQL Server 
- SQL Server Management Studio (SSMS)
- Visual Studio Community 
- SQL Server Integration Services (SSIS)
- SQL Server Database Project
- Analysis Services Tabular Project
- Report Server Project

---

# Modelo de Datos

## Base de datos NorthWindOLTP (Modelo OLTP)

La base de datos transaccional contiene tablas normalizadas para manejar operaciones transaccionales.

Las principales tablas son:

- Customers
- Orders
- Order Details
- Products
- Categories
- Suppliers
- Employees

Estas tablas están relacionadas mediante claves primarias y foráneas para mantener la integridad de los datos.

---

## Base de datos NorthWindDW (Data Warehouse)

Para el análisis de información se implementó un modelo estrella compuesto por:

### Tabla de hechos

- FactSales

### Tablas dimensión

- DimDate
- DimCustomer
- DimProduct
- DimEmployee
- DimGeography

---

# Diagrama de los Modelos

```md
<img width="975" height="980" alt="image" src="https://github.com/user-attachments/assets/66e9f36b-3ec6-49e8-ae47-ce418ec804c8" />


<img width="975" height="1030" alt="image" src="https://github.com/user-attachments/assets/394372b3-c6b1-4841-986c-44e85678c160" />

```

---

# Instrucciones para Desplegar

## Requisitos

Instalar:

- SQL Server 
- SQL Server Management Studio (SSMS)
- Visual Studio Community 
- SQL Server Integration Services (SSIS)
- SQL Server Database Project
- Analysis Services Tabular Project
- Report Server Project

---

## 1. Crear la base de datos OLTP

Abrir SQL Server Management Studio y ejecutar el archivo:

```sql
scriptOLTP.sql
```

Esto creará la base de datos:

```text
NorthWindOLTP
```

---

## 2. Crear el Data Warehouse

Ejecutar el archivo:

```sql
NorthWindDW.sql
```

Esto generará la base de datos:

```text
NorthWindDW
```

---

## 3. Abrir el proyecto en Visual Studio

1. Abrir Visual Studio Community 2022
2. Cargar el proyecto SSIS
3. Configurar la conexión con SQL Server

---

## 4. Ejecutar procesos ETL

1. Abrir los paquetes SSIS
2. Ejecutar los Data Flow Tasks
3. Verificar la carga en dimensiones y FactSales
3. Ejecutar los Data Flow Tasks
4. Verificar la carga en dimensiones y FactSales
