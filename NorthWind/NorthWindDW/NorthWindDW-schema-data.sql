-- ============================================================
-- NorthWind Data Warehouse
-- Script completo y definitivo
-- Incluye: Schema, DimDate, PackageConfig,
--          Stored Procedures de control y merge
-- ============================================================

USE [master]
GO

-- ============================================================
-- 1. CREAR BASE DE DATOS
-- ============================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'NorthWindDW')
    DROP DATABASE [NorthWindDW]
GO

CREATE DATABASE [NorthWindDW]
GO

USE [NorthWindDW]
GO

-- ============================================================
-- 2. SCHEMA STAGING
-- ============================================================
CREATE SCHEMA [staging]
GO

-- ============================================================
-- 3. DIMENSIONES
-- ============================================================

-- ------------------------------------------------------------
-- DimDate
-- ------------------------------------------------------------
CREATE TABLE [dbo].[DimDate](
    [DateKey]           [int]          NOT NULL,
    [FullDate]          [date]         NOT NULL,
    [DayNumberOfWeek]   [tinyint]      NOT NULL,
    [DayNameOfWeek]     [nvarchar](10) NOT NULL,
    [DayNumberOfMonth]  [tinyint]      NOT NULL,
    [DayNumberOfYear]   [smallint]     NOT NULL,
    [WeekNumberOfYear]  [tinyint]      NOT NULL,
    [MonthName]         [nvarchar](10) NOT NULL,
    [MonthNumberOfYear] [tinyint]      NOT NULL,
    [CalendarQuarter]   [tinyint]      NOT NULL,
    [CalendarYear]      [smallint]     NOT NULL,
    [CalendarSemester]  [tinyint]      NOT NULL,
    CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED ([DateKey] ASC)
)
GO

-- ------------------------------------------------------------
-- DimCustomer
-- Fuente: Customers + CustomerCustomerDemo + CustomerDemographics
-- ------------------------------------------------------------
CREATE TABLE [dbo].[DimCustomer](
    [CustomerSK]   [int]           IDENTITY(1,1) NOT NULL,
    [CustomerID]   [nchar](5)      NOT NULL,
    [CompanyName]  [nvarchar](40)  NOT NULL,
    [ContactName]  [nvarchar](30)  NULL,
    [ContactTitle] [nvarchar](30)  NULL,
    [Address]      [nvarchar](60)  NULL,
    [City]         [nvarchar](15)  NULL,
    [Region]       [nvarchar](15)  NULL,
    [PostalCode]   [nvarchar](10)  NULL,
    [Country]      [nvarchar](15)  NULL,
    [Phone]        [nvarchar](24)  NULL,
    [Fax]          [nvarchar](24)  NULL,
    [CustomerDesc] [nvarchar](max) NULL,
    CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerSK] ASC)
)
GO

-- ------------------------------------------------------------
-- DimEmployee
-- Fuente: Employees + EmployeeTerritories + Territories + Region
-- ------------------------------------------------------------
CREATE TABLE [dbo].[DimEmployee](
    [EmployeeSK]           [int]           IDENTITY(1,1) NOT NULL,
    [EmployeeID]           [int]           NOT NULL,
    [LastName]             [nvarchar](20)  NOT NULL,
    [FirstName]            [nvarchar](10)  NOT NULL,
    [Title]                [nvarchar](30)  NULL,
    [TitleOfCourtesy]      [nvarchar](25)  NULL,
    [BirthDate]            [datetime]      NULL,
    [HireDate]             [datetime]      NULL,
    [Address]              [nvarchar](60)  NULL,
    [City]                 [nvarchar](15)  NULL,
    [Region]               [nvarchar](15)  NULL,
    [PostalCode]           [nvarchar](10)  NULL,
    [Country]              [nvarchar](15)  NULL,
    [HomePhone]            [nvarchar](24)  NULL,
    [Extension]            [nvarchar](4)   NULL,
    [Notes]                [nvarchar](max) NULL,
    [ReportsToSK]          [int]           NULL,
    [PhotoPath]            [nvarchar](255) NULL,
    [TerritoryDescription] [nvarchar](50)  NULL,
    [RegionDescription]    [nchar](50)     NULL,
    CONSTRAINT [PK_DimEmployee] PRIMARY KEY CLUSTERED ([EmployeeSK] ASC)
)
GO

-- ------------------------------------------------------------
-- DimProduct
-- Fuente: Products + Categories + Suppliers
-- ------------------------------------------------------------
CREATE TABLE [dbo].[DimProduct](
    [ProductSK]       [int]           IDENTITY(1,1) NOT NULL,
    [ProductID]       [int]           NOT NULL,
    [ProductName]     [nvarchar](40)  NOT NULL,
    [CompanyName]     [nvarchar](40)  NULL,         -- Suppliers.CompanyName
    [CategoryName]    [nvarchar](15)  NULL,
    [Description]     [nvarchar](max) NULL,         -- Categories.Description
    [QuantityPerUnit] [nvarchar](20)  NULL,
    [UnitPrice]       [money]         NULL,
    [UnitsInStock]    [smallint]      NULL,
    [UnitsOnOrder]    [smallint]      NULL,
    [ReorderLevel]    [smallint]      NULL,
    [Discontinued]    [bit]           NOT NULL,
    CONSTRAINT [PK_DimProduct] PRIMARY KEY CLUSTERED ([ProductSK] ASC)
)
GO

-- ------------------------------------------------------------
-- DimShipper
-- Fuente: Shippers
-- ------------------------------------------------------------
CREATE TABLE [dbo].[DimShipper](
    [ShipperSK]   [int]          IDENTITY(1,1) NOT NULL,
    [ShipperID]   [int]          NOT NULL,
    [CompanyName] [nvarchar](40) NOT NULL,
    [Phone]       [nvarchar](24) NULL,
    CONSTRAINT [PK_DimShipper] PRIMARY KEY CLUSTERED ([ShipperSK] ASC)
)
GO

-- ============================================================
-- 4. TABLA DE HECHOS
-- ============================================================

-- ------------------------------------------------------------
-- FactOrders
-- Granularidad: 1 fila por linea de detalle (OrderID + ProductID)
-- Fuente: Orders + OrderDetails
-- ------------------------------------------------------------
CREATE TABLE [dbo].[FactOrders](
    -- Claves
    [OrderID]         [int]      NOT NULL,
    [ProductID]       [int]      NOT NULL,
    -- Foreign Keys a dimensiones de tiempo
    [OrderDateKey]    [int]      NOT NULL,
    [RequiredDateKey] [int]      NOT NULL,
    [ShippedDateKey]  [int]      NOT NULL,
    -- Foreign Keys a dimensiones
    [CustomerSK]      [int]      NULL,
    [EmployeeSK]      [int]      NULL,
    [ProductSK]       [int]      NULL,
    [ShipperSK]       [int]      NULL,
    -- Medidas
    [UnitPrice]       [money]    NOT NULL,
    [Quantity]        [smallint] NOT NULL,
    [Discount]        [real]     NOT NULL,
    [ExtendedPrice]   [money]    NOT NULL,
    [Freight]         [money]    NULL,
    -- Dimensiones degeneradas (drill-through)
    [OrderDate]       [datetime] NULL,
    [RequiredDate]    [datetime] NULL,
    [ShippedDate]     [datetime] NULL,
    CONSTRAINT [PK_FactOrders] PRIMARY KEY CLUSTERED ([OrderID] ASC, [ProductID] ASC)
)
GO

-- ============================================================
-- 5. FOREIGN KEYS DE FACTORDERS
-- ============================================================
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimDate_Order]
    FOREIGN KEY([OrderDateKey]) REFERENCES [dbo].[DimDate]([DateKey])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimDate_Required]
    FOREIGN KEY([RequiredDateKey]) REFERENCES [dbo].[DimDate]([DateKey])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimDate_Shipped]
    FOREIGN KEY([ShippedDateKey]) REFERENCES [dbo].[DimDate]([DateKey])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimCustomer]
    FOREIGN KEY([CustomerSK]) REFERENCES [dbo].[DimCustomer]([CustomerSK])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimEmployee]
    FOREIGN KEY([EmployeeSK]) REFERENCES [dbo].[DimEmployee]([EmployeeSK])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimProduct]
    FOREIGN KEY([ProductSK]) REFERENCES [dbo].[DimProduct]([ProductSK])
GO
ALTER TABLE [dbo].[FactOrders] WITH CHECK ADD
    CONSTRAINT [FK_Fact_DimShipper]
    FOREIGN KEY([ShipperSK]) REFERENCES [dbo].[DimShipper]([ShipperSK])
GO

-- ============================================================
-- 6. TABLAS STAGING
-- ============================================================

-- ------------------------------------------------------------
-- staging.customer
-- ------------------------------------------------------------
CREATE TABLE [staging].[customer](
    [CustomerID]   [nchar](5)      NOT NULL,
    [CompanyName]  [nvarchar](40)  NOT NULL,
    [ContactName]  [nvarchar](30)  NULL,
    [ContactTitle] [nvarchar](30)  NULL,
    [Address]      [nvarchar](60)  NULL,
    [City]         [nvarchar](15)  NULL,
    [Region]       [nvarchar](15)  NULL,
    [PostalCode]   [nvarchar](10)  NULL,
    [Country]      [nvarchar](15)  NULL,
    [Phone]        [nvarchar](24)  NULL,
    [Fax]          [nvarchar](24)  NULL,
    [CustomerDesc] [nvarchar](max) NULL
)
GO

-- ------------------------------------------------------------
-- staging.employee
-- ------------------------------------------------------------
CREATE TABLE [staging].[employee](
    [EmployeeID]           [int]           NOT NULL,
    [LastName]             [nvarchar](20)  NOT NULL,
    [FirstName]            [nvarchar](10)  NOT NULL,
    [Title]                [nvarchar](30)  NULL,
    [TitleOfCourtesy]      [nvarchar](25)  NULL,
    [BirthDate]            [datetime]      NULL,
    [HireDate]             [datetime]      NULL,
    [Address]              [nvarchar](60)  NULL,
    [City]                 [nvarchar](15)  NULL,
    [Region]               [nvarchar](15)  NULL,
    [PostalCode]           [nvarchar](10)  NULL,
    [Country]              [nvarchar](15)  NULL,
    [HomePhone]            [nvarchar](24)  NULL,
    [Extension]            [nvarchar](4)   NULL,
    [Notes]                [nvarchar](max) NULL,
    [ReportsTo]            [int]           NULL,
    [PhotoPath]            [nvarchar](255) NULL,
    [TerritoryDescription] [nvarchar](50)  NULL,
    [RegionDescription]    [nchar](50)     NULL
)
GO

-- ------------------------------------------------------------
-- staging.product
-- ------------------------------------------------------------
CREATE TABLE [staging].[product](
    [ProductID]       [int]           NOT NULL,
    [ProductName]     [nvarchar](40)  NOT NULL,
    [CompanyName]     [nvarchar](40)  NULL,         -- Suppliers.CompanyName
    [CategoryName]    [nvarchar](15)  NULL,
    [Description]     [nvarchar](max) NULL,         -- Categories.Description
    [QuantityPerUnit] [nvarchar](20)  NULL,
    [UnitPrice]       [money]         NULL,
    [UnitsInStock]    [smallint]      NULL,
    [UnitsOnOrder]    [smallint]      NULL,
    [ReorderLevel]    [smallint]      NULL,
    [Discontinued]    [bit]           NOT NULL
)
GO

-- ------------------------------------------------------------
-- staging.shipper
-- ------------------------------------------------------------
CREATE TABLE [staging].[shipper](
    [ShipperID]   [int]          NOT NULL,
    [CompanyName] [nvarchar](40) NOT NULL,
    [Phone]       [nvarchar](24) NULL
)
GO

-- ------------------------------------------------------------
-- staging.orders
-- ------------------------------------------------------------
CREATE TABLE [staging].[orders](
    [OrderID]         [int]      NOT NULL,
    [ProductID]       [int]      NOT NULL,
    [OrderDateKey]    [int]      NOT NULL,
    [RequiredDateKey] [int]      NOT NULL,
    [ShippedDateKey]  [int]      NOT NULL,
    [CustomerSK]      [int]      NULL,
    [EmployeeSK]      [int]      NULL,
    [ProductSK]       [int]      NULL,
    [ShipperSK]       [int]      NULL,
    [UnitPrice]       [money]    NOT NULL,
    [Quantity]        [smallint] NOT NULL,
    [Discount]        [real]     NOT NULL,
    [ExtendedPrice]   [money]    NOT NULL,
    [Freight]         [money]    NULL,
    [OrderDate]       [datetime] NULL,
    [RequiredDate]    [datetime] NULL,
    [ShippedDate]     [datetime] NULL
)
GO

-- ============================================================
-- 7. CONTROL DE CARGA - PackageConfig
-- ============================================================
CREATE TABLE [dbo].[PackageConfig](
    [PackageID]      [int]         IDENTITY(1,1) NOT NULL,
    [TableName]      [varchar](50) NOT NULL,
    [LastRowVersion] [bigint]      NULL,
    CONSTRAINT [PK_PackageConfig] PRIMARY KEY CLUSTERED ([PackageID] ASC)
)
GO

-- Registros iniciales
INSERT [dbo].[PackageConfig] ([TableName],[LastRowVersion]) VALUES ('Customer', 0)
INSERT [dbo].[PackageConfig] ([TableName],[LastRowVersion]) VALUES ('Employee', 0)
INSERT [dbo].[PackageConfig] ([TableName],[LastRowVersion]) VALUES ('Product',  0)
INSERT [dbo].[PackageConfig] ([TableName],[LastRowVersion]) VALUES ('Shipper',  0)
INSERT [dbo].[PackageConfig] ([TableName],[LastRowVersion]) VALUES ('Orders',   0)
GO

-- ============================================================
-- 8. POBLAR DIMDATE (1990-01-01 al 2030-01-01)
-- ============================================================
BEGIN TRAN
    DECLARE @startdate DATE = '1990-01-01',
            @enddate   DATE = '2030-01-01';
    DECLARE @datelist TABLE(FullDate DATE);

    WHILE (@startdate <= @enddate)
    BEGIN
        INSERT INTO @datelist(FullDate) SELECT @startdate;
        SET @startdate = DATEADD(dd, 1, @startdate);
    END

    INSERT INTO [dbo].[DimDate](
         [DateKey],[FullDate],[DayNumberOfWeek],[DayNameOfWeek],
         [DayNumberOfMonth],[DayNumberOfYear],[WeekNumberOfYear],
         [MonthName],[MonthNumberOfYear],[CalendarQuarter],
         [CalendarYear],[CalendarSemester])
    SELECT
         CONVERT(INT, CONVERT(VARCHAR, dl.FullDate, 112))
        ,dl.FullDate
        ,DATEPART(dw,  dl.FullDate)
        ,DATENAME(WEEKDAY, dl.FullDate)
        ,DATEPART(d,   dl.FullDate)
        ,DATEPART(dy,  dl.FullDate)
        ,DATEPART(wk,  dl.FullDate)
        ,DATENAME(MONTH, dl.FullDate)
        ,MONTH(dl.FullDate)
        ,DATEPART(qq,  dl.FullDate)
        ,YEAR(dl.FullDate)
        ,CASE DATEPART(qq, dl.FullDate)
            WHEN 1 THEN 1 WHEN 2 THEN 1
            WHEN 3 THEN 2 WHEN 4 THEN 2
         END
    FROM @datelist dl
    LEFT JOIN [dbo].[DimDate] dd ON dl.FullDate = dd.FullDate
    WHERE dd.FullDate IS NULL;
COMMIT TRAN
GO

-- Registro especial para ShippedDate NULL
INSERT INTO [dbo].[DimDate]
    ([DateKey],[FullDate],[DayNumberOfWeek],[DayNameOfWeek],
     [DayNumberOfMonth],[DayNumberOfYear],[WeekNumberOfYear],
     [MonthName],[MonthNumberOfYear],[CalendarQuarter],
     [CalendarYear],[CalendarSemester])
VALUES (0, GETDATE(), 0, '', 0, 0, 1, '', 0, 0, 0, 0)
GO

-- ============================================================
-- 9. STORED PROCEDURES DE CONTROL
-- ============================================================

-- ------------------------------------------------------------
-- GetLastPackageRowVersion
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetLastPackageRowVersion]
(
    @tableName VARCHAR(50)
)
AS
BEGIN
    SELECT [LastRowVersion]
    FROM [dbo].[PackageConfig]
    WHERE [TableName] = @tableName;
END
GO

-- ------------------------------------------------------------
-- UpdateLastPackageRowVersion
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[UpdateLastPackageRowVersion]
(
    @tableName      VARCHAR(50),
    @lastRowVersion BIGINT
)
AS
BEGIN
    UPDATE [dbo].[PackageConfig]
    SET [LastRowVersion] = @lastRowVersion
    WHERE [TableName] = @tableName;
END
GO

-- ============================================================
-- 10. STORED PROCEDURES DE MERGE (STAGING → DW)
-- ============================================================

-- ------------------------------------------------------------
-- DW_MergeDimCustomer
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[DW_MergeDimCustomer]
AS
BEGIN
    SET NOCOUNT ON;

    -- UPDATE registros existentes
    UPDATE dc
    SET  [CompanyName]  = sc.[CompanyName]
        ,[ContactName]  = sc.[ContactName]
        ,[ContactTitle] = sc.[ContactTitle]
        ,[Address]      = sc.[Address]
        ,[City]         = sc.[City]
        ,[Region]       = sc.[Region]
        ,[PostalCode]   = sc.[PostalCode]
        ,[Country]      = sc.[Country]
        ,[Phone]        = sc.[Phone]
        ,[Fax]          = sc.[Fax]
        ,[CustomerDesc] = sc.[CustomerDesc]
    FROM [dbo].[DimCustomer]        dc
    INNER JOIN [staging].[customer] sc ON dc.[CustomerID] = sc.[CustomerID];

    -- INSERT nuevos
    INSERT INTO [dbo].[DimCustomer]
        ([CustomerID],[CompanyName],[ContactName],[ContactTitle],
         [Address],[City],[Region],[PostalCode],[Country],
         [Phone],[Fax],[CustomerDesc])
    SELECT
         sc.[CustomerID], sc.[CompanyName], sc.[ContactName], sc.[ContactTitle]
        ,sc.[Address], sc.[City], sc.[Region], sc.[PostalCode], sc.[Country]
        ,sc.[Phone], sc.[Fax], sc.[CustomerDesc]
    FROM [staging].[customer] sc
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[DimCustomer] dc
        WHERE dc.[CustomerID] = sc.[CustomerID]
    );
END
GO

-- ------------------------------------------------------------
-- DW_MergeDimEmployee
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[DW_MergeDimEmployee]
AS
BEGIN
    SET NOCOUNT ON;

    -- UPDATE existentes
    UPDATE de
    SET  [LastName]             = se.[LastName]
        ,[FirstName]            = se.[FirstName]
        ,[Title]                = se.[Title]
        ,[TitleOfCourtesy]      = se.[TitleOfCourtesy]
        ,[BirthDate]            = se.[BirthDate]
        ,[HireDate]             = se.[HireDate]
        ,[Address]              = se.[Address]
        ,[City]                 = se.[City]
        ,[Region]               = se.[Region]
        ,[PostalCode]           = se.[PostalCode]
        ,[Country]              = se.[Country]
        ,[HomePhone]            = se.[HomePhone]
        ,[Extension]            = se.[Extension]
        ,[Notes]                = se.[Notes]
        ,[ReportsToSK]          = mgr.[EmployeeSK]
        ,[PhotoPath]            = se.[PhotoPath]
        ,[TerritoryDescription] = se.[TerritoryDescription]
        ,[RegionDescription]    = se.[RegionDescription]
    FROM [dbo].[DimEmployee]        de
    INNER JOIN [staging].[employee] se  ON de.[EmployeeID]  = se.[EmployeeID]
    LEFT  JOIN [dbo].[DimEmployee]  mgr ON mgr.[EmployeeID] = se.[ReportsTo];

    -- INSERT nuevos
    INSERT INTO [dbo].[DimEmployee]
        ([EmployeeID],[LastName],[FirstName],[Title],[TitleOfCourtesy],
         [BirthDate],[HireDate],[Address],[City],[Region],[PostalCode],[Country],
         [HomePhone],[Extension],[Notes],[ReportsToSK],[PhotoPath],
         [TerritoryDescription],[RegionDescription])
    SELECT
         se.[EmployeeID], se.[LastName], se.[FirstName], se.[Title], se.[TitleOfCourtesy]
        ,se.[BirthDate], se.[HireDate], se.[Address], se.[City], se.[Region]
        ,se.[PostalCode], se.[Country], se.[HomePhone], se.[Extension], se.[Notes]
        ,mgr.[EmployeeSK]
        ,se.[PhotoPath], se.[TerritoryDescription], se.[RegionDescription]
    FROM [staging].[employee] se
    LEFT JOIN [dbo].[DimEmployee] mgr ON mgr.[EmployeeID] = se.[ReportsTo]
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[DimEmployee] de
        WHERE de.[EmployeeID] = se.[EmployeeID]
    );
END
GO

-- ------------------------------------------------------------
-- DW_MergeDimProduct
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[DW_MergeDimProduct]
AS
BEGIN
    SET NOCOUNT ON;

    -- UPDATE existentes
    UPDATE dp
    SET  [ProductName]     = sp.[ProductName]
        ,[CompanyName]     = sp.[CompanyName]
        ,[CategoryName]    = sp.[CategoryName]
        ,[Description]     = sp.[Description]
        ,[QuantityPerUnit] = sp.[QuantityPerUnit]
        ,[UnitPrice]       = sp.[UnitPrice]
        ,[UnitsInStock]    = sp.[UnitsInStock]
        ,[UnitsOnOrder]    = sp.[UnitsOnOrder]
        ,[ReorderLevel]    = sp.[ReorderLevel]
        ,[Discontinued]    = sp.[Discontinued]
    FROM [dbo].[DimProduct]        dp
    INNER JOIN [staging].[product] sp ON dp.[ProductID] = sp.[ProductID];

    -- INSERT nuevos
    INSERT INTO [dbo].[DimProduct]
        ([ProductID],[ProductName],[CompanyName],[CategoryName],[Description],
         [QuantityPerUnit],[UnitPrice],[UnitsInStock],[UnitsOnOrder],
         [ReorderLevel],[Discontinued])
    SELECT
         sp.[ProductID], sp.[ProductName], sp.[CompanyName], sp.[CategoryName], sp.[Description]
        ,sp.[QuantityPerUnit], sp.[UnitPrice], sp.[UnitsInStock], sp.[UnitsOnOrder]
        ,sp.[ReorderLevel], sp.[Discontinued]
    FROM [staging].[product] sp
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[DimProduct] dp
        WHERE dp.[ProductID] = sp.[ProductID]
    );
END
GO

-- ------------------------------------------------------------
-- DW_MergeDimShipper
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[DW_MergeDimShipper]
AS
BEGIN
    SET NOCOUNT ON;

    -- UPDATE existentes
    UPDATE ds
    SET  [CompanyName] = ss.[CompanyName]
        ,[Phone]       = ss.[Phone]
    FROM [dbo].[DimShipper]        ds
    INNER JOIN [staging].[shipper] ss ON ds.[ShipperID] = ss.[ShipperID];

    -- INSERT nuevos
    INSERT INTO [dbo].[DimShipper] ([ShipperID],[CompanyName],[Phone])
    SELECT ss.[ShipperID], ss.[CompanyName], ss.[Phone]
    FROM [staging].[shipper] ss
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[DimShipper] ds
        WHERE ds.[ShipperID] = ss.[ShipperID]
    );
END
GO

-- ------------------------------------------------------------
-- DW_MergeFactOrders
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[DW_MergeFactOrders]
AS
BEGIN
    SET NOCOUNT ON;

    -- UPDATE existentes
    UPDATE fo
    SET  [OrderDateKey]    = so.[OrderDateKey]
        ,[RequiredDateKey] = so.[RequiredDateKey]
        ,[ShippedDateKey]  = so.[ShippedDateKey]
        ,[CustomerSK]      = so.[CustomerSK]
        ,[EmployeeSK]      = so.[EmployeeSK]
        ,[ProductSK]       = so.[ProductSK]
        ,[ShipperSK]       = so.[ShipperSK]
        ,[UnitPrice]       = so.[UnitPrice]
        ,[Quantity]        = so.[Quantity]
        ,[Discount]        = so.[Discount]
        ,[ExtendedPrice]   = so.[ExtendedPrice]
        ,[Freight]         = so.[Freight]
        ,[OrderDate]       = so.[OrderDate]
        ,[RequiredDate]    = so.[RequiredDate]
        ,[ShippedDate]     = so.[ShippedDate]
    FROM [dbo].[FactOrders]         fo
    INNER JOIN [staging].[orders]   so
        ON fo.[OrderID] = so.[OrderID] AND fo.[ProductID] = so.[ProductID];

    -- INSERT nuevos
    INSERT INTO [dbo].[FactOrders]
        ([OrderID],[ProductID],[OrderDateKey],[RequiredDateKey],[ShippedDateKey],
         [CustomerSK],[EmployeeSK],[ProductSK],[ShipperSK],
         [UnitPrice],[Quantity],[Discount],[ExtendedPrice],[Freight],
         [OrderDate],[RequiredDate],[ShippedDate])
    SELECT
         so.[OrderID], so.[ProductID], so.[OrderDateKey], so.[RequiredDateKey], so.[ShippedDateKey]
        ,so.[CustomerSK], so.[EmployeeSK], so.[ProductSK], so.[ShipperSK]
        ,so.[UnitPrice], so.[Quantity], so.[Discount], so.[ExtendedPrice], so.[Freight]
        ,so.[OrderDate], so.[RequiredDate], so.[ShippedDate]
    FROM [staging].[orders] so
    WHERE NOT EXISTS (
        SELECT 1 FROM [dbo].[FactOrders] fo
        WHERE fo.[OrderID] = so.[OrderID] AND fo.[ProductID] = so.[ProductID]
    );
END
GO
