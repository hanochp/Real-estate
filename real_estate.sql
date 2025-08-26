-- T-SQL script to set up real estate database, seed sample data, and provide requested reports

USE master;
GO

IF DB_ID('RealEstate') IS NOT NULL
BEGIN
    ALTER DATABASE RealEstate SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RealEstate;
END;
GO
CREATE DATABASE RealEstate;
GO

USE RealEstate;
GO

IF OBJECT_ID('dbo.House', 'U') IS NOT NULL
    DROP TABLE dbo.House;
GO

CREATE TABLE dbo.House (
    HouseID INT IDENTITY(1,1) CONSTRAINT PK_House PRIMARY KEY,
    Address NVARCHAR(200) NOT NULL,
    Town NVARCHAR(50) NOT NULL
        CONSTRAINT CK_House_Town CHECK (Town IN ('Lakewood','Jackson','Toms River','Howell','Brick','Manchester')),
    HouseType NVARCHAR(20) NOT NULL
        CONSTRAINT CK_House_HouseType CHECK (HouseType IN ('bi-level','colonial','ranch','split-level','duplex','townhouse','vacant land','apartment')),
    Bedrooms TINYINT NOT NULL
        CONSTRAINT CK_House_Bedrooms_NonNegative CHECK (Bedrooms >= 0),
    Bathrooms DECIMAL(3,1) NOT NULL
        CONSTRAINT CK_House_Bathrooms_NonNegative CHECK (Bathrooms >= 0),
    HouseSqFt INT NOT NULL
        CONSTRAINT CK_House_HouseSqFt_Positive CHECK (HouseSqFt > 0),
    LotSqFt DECIMAL(10,1) NOT NULL
        CONSTRAINT CK_House_LotSqFt_Positive CHECK (LotSqFt > 0),
    Owner NVARCHAR(100) NOT NULL,
    ClientContact NVARCHAR(100) NOT NULL,
    Realtor NVARCHAR(100) NOT NULL,
    DateOnMarket DATE NOT NULL,
    DateSold DATE NULL,
    AskingPrice MONEY NOT NULL
        CONSTRAINT CK_House_AskingPrice_Range CHECK (AskingPrice BETWEEN 100000 AND 9900000),
    SoldPrice MONEY NULL
        CONSTRAINT CK_House_SoldPrice_Range CHECK (SoldPrice BETWEEN 100000 AND 9900000),
    Buyer NVARCHAR(100) NULL,
    IsInContract BIT NOT NULL
        CONSTRAINT DF_House_IsInContract DEFAULT 0,
    CONSTRAINT CK_House_SoldPrice_GE_Asking CHECK (SoldPrice IS NULL OR SoldPrice >= AskingPrice),
    CONSTRAINT CK_House_DateSold CHECK (DateSold IS NULL OR DateSold >= DateOnMarket),
    CONSTRAINT CK_House_SaleState CHECK (
        (DateSold IS NOT NULL AND SoldPrice IS NOT NULL AND Buyer IS NOT NULL AND IsInContract = 0) OR
        (DateSold IS NULL AND (
            (IsInContract = 1 AND SoldPrice IS NOT NULL AND Buyer IS NOT NULL) OR
            (IsInContract = 0 AND SoldPrice IS NULL AND Buyer IS NULL)
        ))
    )
);
GO

INSERT INTO dbo.House (Address, Town, HouseType, Bedrooms, Bathrooms, HouseSqFt, LotSqFt, Owner, ClientContact, Realtor, DateOnMarket, DateSold, AskingPrice, SoldPrice, Buyer, IsInContract)
VALUES
('5 Lynn Drive', 'Toms River', 'colonial', 4, 2.5, 3000, 42000, 'Lynn Drive, LLC', 'Yaakov Fishman', 'Rivka Harnik', '2021-01-12', '2021-02-22', 450000, 475000, 'Rachel Gestetner', 0),
('8 London Drive', 'Lakewood', 'ranch', 3, 2, 2000, 4089, 'Shaindy Braun', 'Shaindy Braun', 'Raizy Berger', '2009-04-05', '2010-07-10', 200000, 200000, 'Elazar and Faigy Adler', 0),
('423 2nd Street', 'Lakewood', 'colonial', 9, 5.5, 3500, 4200, 'L3C Jackson, LLC', 'Mark Farkas', 'Rivka Harnik', '2015-01-06', '2015-06-09', 360000, 370000, 'Yossi Handler and Rivky Handler', 0),
('176 Hadassah Lane', 'Lakewood', 'duplex', 5, 2.5, 2550, 3049.2, 'Greenview Equities, LLC', 'shlomo press', 'Moshe Celnik', '2021-05-03', NULL, 549000, 600000, 'Shea Speigel', 1),
('1141 Central Avenue', 'Lakewood', 'ranch', 3, 1, 855, 5000, 'Sorah Hager', 'Yitzchok Tendler', 'Moshe Celnik', '2022-01-02', NULL, 300000, NULL, NULL, 0);
GO

-- 1) Report: all houses sorted by block (numeric portion of address) then by town
SELECT *
FROM dbo.House
ORDER BY TRY_CONVERT(INT, LEFT(Address, CHARINDEX(' ', Address + ' ') - 1)), Town;
GO

-- 2) Report: all houses sorted by realtor
SELECT *
FROM dbo.House
ORDER BY Realtor, Address;
GO

-- 3) Report: how long it took for each house to sell
SELECT Address, Town, DATEDIFF(day, DateOnMarket, DateSold) AS DaysOnMarket
FROM dbo.House
WHERE DateSold IS NOT NULL;
GO

-- 4) Report: price difference from asking price to sold price
SELECT Address, Town, SoldPrice - AskingPrice AS PriceDifference
FROM dbo.House
WHERE SoldPrice IS NOT NULL;
GO
