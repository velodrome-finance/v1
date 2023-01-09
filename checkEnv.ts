import { z, type ZodFormattedError } from "zod";

const schema = z.object({
  ALCHEMY_GOERLI_ARBITRUM_API_KEY: z.string().min(1),
  ARB_SCAN_API_KEY: z.string().min(1),
});

type DestructedEnv = {
  [k in keyof z.infer<typeof schema>]: z.infer<typeof schema>[k] | undefined;
};

const destructedEnv: DestructedEnv = {
  ALCHEMY_GOERLI_ARBITRUM_API_KEY: process.env.ALCHEMY_GOERLI_ARBITRUM_API_KEY,
  ARB_SCAN_API_KEY: process.env.ARB_SCAN_API_KEY,
};

const _env = schema.safeParse(destructedEnv);

const formatErrors = (
  errors: ZodFormattedError<Map<string, string>, string>
) => {
  return Object.entries(errors)
    .map(([name, value]) => {
      if (value && "_errors" in value)
        return `${name}: ${value._errors.join(", ")}\n`;
    })
    .filter(Boolean);
};

if (!_env.success) {
  console.error(
    "❌ Invalid environment variables:\n",
    ...formatErrors(_env.error.format())
  );
  throw new Error("Invalid environment variables");
}
