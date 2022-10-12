const { expect } = require("chai");
const { ethers } = require("hardhat");

const quotes = [
  [109039634506n, 22114890],
  [108039634506n, 22114891],
  [108029634506n, 22114892],
  [112029634506n, 22114893],
  [113029634506n, 22114894],
];

const sum = (arr) => arr.reduce((acc, [price]) => price + acc, 0n);

describe("Envie", function () {
  it("Average should work", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByAverage(quotes, 5, 22114894, 5)
    ).to.equal(sum(quotes) / 5n);
  });

  it("Average should work with max blocks", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByAverage(quotes, 4, 22114894, 5)
    ).to.equal(sum(quotes.slice(1)) / 4n);
  });

  it("Average should work with max quotes", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByAverage(quotes, 4, 22114894, 3)
    ).to.equal(sum(quotes.slice(2)) / 3n);
  });

  it("Percentile should work", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByPercentile(quotes, 90, 5, 22114894, 5)
    ).to.equal(113029634506n);

    expect(
      await consumer.getTokenPriceByPercentile(quotes, 10, 5, 22114894, 5)
    ).to.equal(108029634506n);

    expect(
      await consumer.getTokenPriceByPercentile(quotes, 50, 5, 22114894, 5)
    ).to.equal(109039634506n);
  });

  it("Percentile should work with max blocks", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByPercentile(quotes, 10, 3, 22114894, 5)
    ).to.equal(108029634506n);
  });

  it("Percentile should work with max quotes", async function () {
    const Consumer = await ethers.getContractFactory("DeFiFeedConsumerTest");
    const consumer = await Consumer.deploy();
    await consumer.deployed();

    expect(
      await consumer.getTokenPriceByPercentile(quotes, 10, 5, 22114894, 2)
    ).to.equal(112029634506n);
  });
});
