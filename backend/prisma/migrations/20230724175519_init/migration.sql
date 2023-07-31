-- CreateTable
CREATE TABLE "Transaction" (
    "id" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "tags" JSONB NOT NULL,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RendererUpdated" (
    "id" TEXT NOT NULL,
    "targetPress" TEXT[],
    "renderer" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RendererUpdated_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PressInitialized" (
    "id" TEXT NOT NULL,
    "targetPress" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "sender" TEXT NOT NULL,

    CONSTRAINT "PressInitialized_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LogicUpdated" (
    "id" TEXT NOT NULL,
    "targetPress" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "logic" TEXT NOT NULL,

    CONSTRAINT "LogicUpdated_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DataStored" (
    "id" TEXT NOT NULL,
    "targetPress" TEXT NOT NULL,
    "storeCaller" TEXT NOT NULL,
    "pointer" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "tokenId" BIGINT NOT NULL,

    CONSTRAINT "DataStored_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Create721Press" (
    "id" TEXT NOT NULL,
    "newPress" TEXT NOT NULL,
    "initialOwner" TEXT NOT NULL,
    "initialLogic" TEXT NOT NULL,
    "creator" TEXT NOT NULL,
    "initialRenderer" TEXT NOT NULL,
    "soulbound" BOOLEAN NOT NULL,

    CONSTRAINT "Create721Press_pkey" PRIMARY KEY ("id")
);
