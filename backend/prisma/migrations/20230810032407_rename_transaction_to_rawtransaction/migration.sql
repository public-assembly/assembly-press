/*
  Warnings:

  - You are about to drop the column `target` on the `AP721` table. All the data in the column will be lost.
  - The primary key for the `TokenStorage` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the `TokenInfo` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Transaction` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `transactionHash` to the `AP721` table without a default value. This is not possible if the table is not empty.
  - Made the column `sender` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Made the column `owner` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Made the column `logic` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Made the column `renderer` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Made the column `factory` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Made the column `createdAt` on table `AP721` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `pointer` to the `TokenStorage` table without a default value. This is not possible if the table is not empty.
  - Added the required column `tokenId` to the `TokenStorage` table without a default value. This is not possible if the table is not empty.
  - Added the required column `transactionHash` to the `TokenStorage` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `TokenStorage` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedBy` to the `TokenStorage` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "TokenInfo" DROP CONSTRAINT "TokenInfo_tokenStorageAp721_fkey";

-- AlterTable
ALTER TABLE "AP721" DROP COLUMN "target",
ADD COLUMN     "transactionHash" TEXT NOT NULL,
ALTER COLUMN "sender" SET NOT NULL,
ALTER COLUMN "owner" SET NOT NULL,
ALTER COLUMN "logic" SET NOT NULL,
ALTER COLUMN "renderer" SET NOT NULL,
ALTER COLUMN "factory" SET NOT NULL,
ALTER COLUMN "createdAt" SET NOT NULL;

-- AlterTable
ALTER TABLE "TokenStorage" DROP CONSTRAINT "TokenStorage_pkey",
ADD COLUMN     "pointer" TEXT NOT NULL,
ADD COLUMN     "tokenId" BIGINT NOT NULL,
ADD COLUMN     "transactionHash" TEXT NOT NULL,
ADD COLUMN     "updatedAt" BIGINT NOT NULL,
ADD COLUMN     "updatedBy" TEXT NOT NULL,
ADD CONSTRAINT "TokenStorage_pkey" PRIMARY KEY ("ap721", "tokenId");

-- DropTable
DROP TABLE "TokenInfo";

-- DropTable
DROP TABLE "Transaction";

-- CreateTable
CREATE TABLE "RawTransaction" (
    "transactionHash" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "createdAt" BIGINT NOT NULL,

    CONSTRAINT "RawTransaction_pkey" PRIMARY KEY ("transactionHash")
);

-- CreateTable
CREATE TABLE "Arweave" (
    "tableName" TEXT NOT NULL,
    "link" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Arweave_pkey" PRIMARY KEY ("link")
);

-- AddForeignKey
ALTER TABLE "AP721" ADD CONSTRAINT "AP721_transactionHash_fkey" FOREIGN KEY ("transactionHash") REFERENCES "RawTransaction"("transactionHash") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TokenStorage" ADD CONSTRAINT "TokenStorage_transactionHash_fkey" FOREIGN KEY ("transactionHash") REFERENCES "RawTransaction"("transactionHash") ON DELETE RESTRICT ON UPDATE CASCADE;
