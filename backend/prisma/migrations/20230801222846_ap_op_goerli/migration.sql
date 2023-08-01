/*
  Warnings:

  - You are about to drop the `Create721Press` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `DataStored` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `LogicUpdated` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `PressInitialized` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `RendererUpdated` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
DROP TABLE "Create721Press";

-- DropTable
DROP TABLE "DataStored";

-- DropTable
DROP TABLE "LogicUpdated";

-- DropTable
DROP TABLE "PressInitialized";

-- DropTable
DROP TABLE "RendererUpdated";

-- CreateTable
CREATE TABLE "AP721" (
    "ap721" TEXT NOT NULL,
    "sender" TEXT,
    "owner" TEXT,
    "logic" TEXT,
    "renderer" TEXT,
    "factory" TEXT,
    "createdAt" BIGINT,
    "target" TEXT,

    CONSTRAINT "AP721_pkey" PRIMARY KEY ("ap721")
);

-- CreateTable
CREATE TABLE "TokenStorage" (
    "ap721" TEXT NOT NULL,

    CONSTRAINT "TokenStorage_pkey" PRIMARY KEY ("ap721")
);

-- CreateTable
CREATE TABLE "TokenInfo" (
    "tokenId" SERIAL NOT NULL,
    "pointer" TEXT NOT NULL,
    "decodedData" TEXT NOT NULL,
    "sender" TEXT NOT NULL,
    "metadata" TEXT NOT NULL,
    "burned" BOOLEAN NOT NULL,
    "updatedAt" TEXT NOT NULL,
    "updatedBy" TEXT NOT NULL,
    "tokenStorageAp721" TEXT,

    CONSTRAINT "TokenInfo_pkey" PRIMARY KEY ("tokenId")
);

-- AddForeignKey
ALTER TABLE "TokenInfo" ADD CONSTRAINT "TokenInfo_tokenStorageAp721_fkey" FOREIGN KEY ("tokenStorageAp721") REFERENCES "TokenStorage"("ap721") ON DELETE SET NULL ON UPDATE CASCADE;
