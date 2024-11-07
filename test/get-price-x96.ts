function encodePriceX96(amount0: bigint, amount1: bigint) {
  const numerator = amount1 << 192n;
  const denominator = amount0;
  const priceX192 = numerator / denominator;
  return sqrt(priceX192);
}

function sqrt(n: bigint): bigint {
  if (n < 0n) throw new Error("Square root of negative number");
  if (n < 2n) return n;
  let x = n;
  let y = (x + 1n) / 2n;
  while (y < x) {
    x = y;
    y = (x * x + n) / (2n * x);
  }
  return x;
}

const amount0 = Deno.args[0];
const amount1 = Deno.args[1];

console.log(encodePriceX96(BigInt(Number(amount0)), BigInt(Number(amount1))));
