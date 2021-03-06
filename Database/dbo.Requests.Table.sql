USE [Later]
GO
/****** Object:  Table [dbo].[Requests]    Script Date: 2019-08-16 14:28:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Requests](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](50) NOT NULL,
	[ComputerName] [nvarchar](50) NOT NULL,
	[ComputerNameByAddress] [nvarchar](50) NULL,
	[ComputerIPAddress] [nvarchar](50) NULL,
	[ComputerNameMatchAddress] [bit] NOT NULL,
	[Timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK__Requests__3214EC075FF5AD14] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Requests] ADD  CONSTRAINT [DF__Requests__Timest__4CA06362]  DEFAULT (getdate()) FOR [Timestamp]
GO
