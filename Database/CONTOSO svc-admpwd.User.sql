USE [Later]
GO
/****** Object:  User [CONTOSO\svc-admpwd]    Script Date: 2019-08-16 14:28:33 ******/
CREATE USER [CONTOSO\svc-admpwd] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_datareader] ADD MEMBER [CONTOSO\svc-admpwd]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [CONTOSO\svc-admpwd]
GO
