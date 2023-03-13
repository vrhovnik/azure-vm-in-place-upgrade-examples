using Microsoft.Azure.Management.Compute.Fluent.Models;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Newtonsoft.Json;
using Spectre.Console;
using UpdateViaManagedAPI;

AnsiConsole.Write(new Rule("Azure [red]InPlace Upgrade[/]"));
if (AnsiConsole.Profile.Capabilities.Links)
    AnsiConsole.MarkupLine(
        "Check [link=https://github.com/vrhovnik/azure-vm-in-place-upgrade-examples]for more information[/]");

var creds = LoadAzureCredentials();
var vmName = Environment.GetEnvironmentVariable("vmName");
if (string.IsNullOrEmpty(vmName))
{
    vmName = AnsiConsole.Prompt(
        new TextPrompt<string>("Enter [green]name of the machine[/] to continue")
            .PromptStyle("green"));
}

var azure = new AzureServices(creds);
//get machine to work with
var machine = await azure.GetMachineByNameAsync(vmName);
//start machine if not running
await azure.StartMachineAsync(machine);
//run the update script with Azure files integration
var scriptPath = Environment.GetEnvironmentVariable("ScriptPath");
if (string.IsNullOrEmpty(scriptPath))
{
    scriptPath = AnsiConsole.Prompt(
        new TextPrompt<string>($"Enter [green]path[/] to script to execute on {vmName}")
            .PromptStyle("green"));
}

AnsiConsole.WriteLine("You have defined the following path:");
var path = new TextPath(scriptPath)
{
    RootStyle = new Style(foreground: Color.Red),
    SeparatorStyle = new Style(foreground: Color.Green),
    StemStyle = new Style(foreground: Color.Blue),
    LeafStyle = new Style(foreground: Color.Yellow)
};
AnsiConsole.Write(path);

var scriptContent = File.ReadAllText(scriptPath);
if (string.IsNullOrEmpty(scriptPath))
{
    AnsiConsole.WriteLine("Script is empty, check path and content.");
    return;
}

var scriptParameterPath = Environment.GetEnvironmentVariable("ScriptParameterPath");
if (string.IsNullOrEmpty(scriptParameterPath))
    await azure.UpdateMachineAsync(machine, scriptContent);
else
{
    AnsiConsole.WriteLine("You have defined the following path for parameters file");
    path = new TextPath(scriptParameterPath)
    {
        RootStyle = new Style(foreground: Color.Red),
        SeparatorStyle = new Style(foreground: Color.Green),
        StemStyle = new Style(foreground: Color.Blue),
        LeafStyle = new Style(foreground: Color.Yellow)
    };
    AnsiConsole.Write(path);
    // reading and setting environment variables
    var jsonString = File.ReadAllText(scriptParameterPath); 
    var deserializedObject = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonString);
    var list = new RunCommandInputParameter[deserializedObject.Count];
    var currentPosition = 0;
    foreach (var pair in deserializedObject)
        list[currentPosition++] = new RunCommandInputParameter(pair.Key, pair.Value);
    //calling script with actions
    await azure.UpdateMachineAsync(machine, scriptContent, list);
}

IAzure LoadAzureCredentials()
{
    var subscriptionId = Environment.GetEnvironmentVariable("IPUSubscriptionId");
    if (string.IsNullOrEmpty(subscriptionId))
    {
        subscriptionId = AnsiConsole.Prompt(
            new TextPrompt<string>("Enter [green]subscription id[/] to continue")
                .PromptStyle("green"));
    }

    AnsiConsole.Write(new Markup($"[bold yellow]Subscription ID[/] to [red]{subscriptionId}[/]"));
    AnsiConsole.WriteLine();

    var clientId = Environment.GetEnvironmentVariable("IPUAppId");
    if (string.IsNullOrEmpty(clientId))
    {
        clientId = AnsiConsole.Prompt(
            new TextPrompt<string>("Enter [green]Azure Ad App id[/] to continue")
                .PromptStyle("green"));
    }

    AnsiConsole.Write(new Markup($"[bold yellow]App Client ID[/] to [red]{clientId}[/]"));
    AnsiConsole.WriteLine();

    var secret = Environment.GetEnvironmentVariable("IPUAppSecret");
    if (string.IsNullOrEmpty(secret))
    {
        secret = AnsiConsole.Prompt(
            new TextPrompt<string>("Enter [green]password[/]?")
                .PromptStyle("red")
                .Secret());
    }

    AnsiConsole.Write(new Markup($"[bold yellow]App Client Secret[/] to [red]{secret}[/]"));
    AnsiConsole.WriteLine();

    var tenantId = Environment.GetEnvironmentVariable("IPUTenantId");
    if (string.IsNullOrEmpty(tenantId))
    {
        tenantId = AnsiConsole.Prompt(
            new TextPrompt<string>("Enter [green]Tenant Id[/]?")
                .PromptStyle("red")
                .Secret());
    }

    AnsiConsole.Write(new Markup($"[bold yellow]Tenant Id[/] to [red]{tenantId}[/]"));
    AnsiConsole.WriteLine();

    var credentials = SdkContext.AzureCredentialsFactory
        .FromServicePrincipal(clientId, secret, tenantId, AzureEnvironment.AzureGlobalCloud);

    //var credentials = new DefaultAzureCredential();
    return Microsoft.Azure.Management.Fluent.Azure.Configure()
        .Authenticate(credentials)
        .WithSubscription(subscriptionId);
}