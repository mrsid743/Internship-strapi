module.exports = ({ env }) => ({
  // Example: upload plugin
  upload: {
    config: {
      provider: 'local',
      providerOptions: {
        sizeLimit: 1000000,
      },
    },
  },
});
