"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const zod_1 = require("zod");
const schema = zod_1.z.object({
    ALCHEMY_GOERLI_ARBITRUM_API_KEY: zod_1.z.string().min(1),
    ARB_SCAN_API_KEY: zod_1.z.string().min(1),
});
const destructedEnv = {
    ALCHEMY_GOERLI_ARBITRUM_API_KEY: process.env.ALCHEMY_GOERLI_ARBITRUM_API_KEY,
    ARB_SCAN_API_KEY: process.env.ARB_SCAN_API_KEY,
};
const _env = schema.safeParse(destructedEnv);
const formatErrors = (errors) => {
    return Object.entries(errors)
        .map(([name, value]) => {
        if (value && "_errors" in value)
            return `${name}: ${value._errors.join(", ")}\n`;
    })
        .filter(Boolean);
};
if (!_env.success) {
    console.error("❌ Invalid environment variables:\n", ...formatErrors(_env.error.format()));
    throw new Error("Invalid environment variables");
}
