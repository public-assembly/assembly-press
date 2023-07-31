/*
  Warnings:

  - The primary key for the `Create721Press` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `Create721Press` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `DataStored` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `DataStored` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `LogicUpdated` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `LogicUpdated` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `PressInitialized` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `PressInitialized` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `RendererUpdated` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The `id` column on the `RendererUpdated` table would be dropped and recreated. This will lead to data loss if there is data in the column.

*/
-- AlterTable
ALTER TABLE "Create721Press" DROP CONSTRAINT "Create721Press_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "Create721Press_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "DataStored" DROP CONSTRAINT "DataStored_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "DataStored_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "LogicUpdated" DROP CONSTRAINT "LogicUpdated_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "LogicUpdated_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "PressInitialized" DROP CONSTRAINT "PressInitialized_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "PressInitialized_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "RendererUpdated" DROP CONSTRAINT "RendererUpdated_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "RendererUpdated_pkey" PRIMARY KEY ("id");
