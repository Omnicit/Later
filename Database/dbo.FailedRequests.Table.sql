USE [Later]
GO
/****** Object:  Table [dbo].[FailedRequests]    Script Date: 2019-08-16 14:28:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FailedRequests](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [nvarchar](50) NOT NULL,
	[ComputerName] [nvarchar](50) NOT NULL,
	[ComputerNameByAddress] [nvarchar](50) NULL,
	[ComputerIPAddress] [nvarchar](50) NULL,
	[ComputerNameMatchAddress] [bit] NOT NULL,
	[Error] [nvarchar](max) NOT NULL,
	[Timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK__FailedRe__3214EC07AC105682] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[FailedRequests] ADD  CONSTRAINT [DF__FailedReq__Times__5CD6CB2B]  DEFAULT (getdate()) FOR [Timestamp]
GO
