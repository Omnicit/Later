USE [Later]
GO
/****** Object:  Table [dbo].[Policy]    Script Date: 2019-08-16 14:28:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Policy](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GroupId] [nvarchar](50) NOT NULL,
	[Computers] [numeric](18, 0) NOT NULL,
	[TimesPerDay] [numeric](18, 0) NOT NULL,
 CONSTRAINT [PK__Policy__3214EC07597E78B5] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
