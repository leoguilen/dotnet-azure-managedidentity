using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Azure;

var builder = Host.CreateDefaultBuilder(args);
builder.ConfigureAppConfiguration((ctx, config) =>
{
    var configBuilded = config.Build();

    config.AddAzureAppConfiguration(options =>
    {
        var appConfigurationEndpoint = configBuilded.GetRequiredSection("Azure:AppConfiguration:Endpoint").Get<Uri>();
        options.Connect(appConfigurationEndpoint, new DefaultAzureCredential());
    });
});
builder.ConfigureServices((ctx, services) =>
{
    services.AddSingleton<IHostedService, ServiceBusEventConsumerService>();
    services.AddAzureClients(clients =>
    {
        clients.UseCredential(new DefaultAzureCredential());
        clients.AddServiceBusClientWithNamespace(ctx.Configuration.GetRequiredSection("Azure:ServiceBus:Namespace").Get<string>());
    });
});
builder.ConfigureHostOptions(opt => opt.StartupTimeout = TimeSpan.FromSeconds(30));
builder.UseConsoleLifetime(options => options.SuppressStatusMessages = true);

var host = builder.Build();
await host.RunAsync().ConfigureAwait(false);

internal sealed class ServiceBusEventConsumerService(
    ServiceBusClient serviceBusClient,
    IConfiguration configuration,
    ILogger<ServiceBusEventConsumerService> logger)
    : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var queueName = configuration.GetRequiredSection("Azure:ServiceBus:QueueName").Get<string>();
        var processor = serviceBusClient.CreateProcessor(queueName, new ServiceBusProcessorOptions
        {
            AutoCompleteMessages = false,
            MaxConcurrentCalls = 1,
        });

        processor.ProcessMessageAsync += async args =>
        {
            var message = args.Message.Body.ToString();
            logger.LogInformation("Received message: {Message}", message);
            await args.CompleteMessageAsync(args.Message, args.CancellationToken);
        };
        processor.ProcessErrorAsync += args =>
        {
            logger.LogError(args.Exception, "Error while processing message");
            return Task.CompletedTask;
        };

        await processor.StartProcessingAsync(stoppingToken);

        stoppingToken.Register(async () =>
        {
            while (processor.IsProcessing)
            {
                logger.LogWarning("Waiting for all the messages to be processed before stopping");
                await Task.Delay(TimeSpan.FromSeconds(1), stoppingToken);
            }

            await processor.StopProcessingAsync();
            logger.LogInformation("Stopped processing messages");
        });
    }
}