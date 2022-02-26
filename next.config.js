require("dotenv").config();

module.exports = {
  reactStrictMode: true,
    env: {
        NEXT_PUBLIC_WORKSPACE_URL : process.env.NEXT_PUBLIC_WORKSPACE_URL,
    }
};
