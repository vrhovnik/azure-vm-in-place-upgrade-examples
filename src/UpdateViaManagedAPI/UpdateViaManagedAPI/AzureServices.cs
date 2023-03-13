using System.Diagnostics;
using Microsoft.Azure.Management.Compute.Fluent;
using Microsoft.Azure.Management.Compute.Fluent.Models;
using Microsoft.Azure.Management.Fluent;
using Spectre.Console;

namespace UpdateViaManagedAPI;

public class AzureServices
{
    private readonly IAzure azure;

    public AzureServices(IAzure azure) => this.azure = azure;

    public async Task UpdateMachineAsync(IVirtualMachine machine, string content,
        params RunCommandInputParameter[] runCommandInputParameters)
    {
        try
        {
            AnsiConsole.WriteLine($"Executing script {content}");
            AnsiConsole.WriteLine("with parameters");

            var table = new Table()
                .AddColumn("Name")
                .AddColumn("Value");
            
            foreach (var parameter in runCommandInputParameters)
            {
                table.AddRow(parameter.Name, parameter.Value);
            }
            
            AnsiConsole.Write(table);

            AnsiConsole.WriteLine();
            AnsiConsole.WriteLine("Executing script");
            
            var stopWatch = Stopwatch.StartNew();
            stopWatch.Start();
            
            var commandResultInner = await machine.RunPowerShellScriptAsync(new List<string> { content },
                runCommandInputParameters);
            
            stopWatch.Stop();
            AnsiConsole.WriteLine($"Script executed in {stopWatch.ElapsedMilliseconds} ms.");

            table = new Table()
                .AddColumn("Display status")
                .AddColumn("Message");
            foreach (var status in commandResultInner.Value)
            {
                table.AddRow(status.DisplayStatus, status.Message);
            }
            AnsiConsole.Write(table);
        }
        catch (Exception e)
        {
            AnsiConsole.WriteException(e);
        }
    }

    public async Task<IVirtualMachine> GetMachineByNameAsync(string name)
    {
        var virtualMachines = await azure.VirtualMachines.ListAsync(true, CancellationToken.None);
        var virtualMachine = virtualMachines.FirstOrDefault(d => d.Name == name);
        if (virtualMachine == null)
        {
            var error = $"Machine with name {name} was not found, check Azure Resources.";
            AnsiConsole.WriteLine(error);
            throw new AzureException(error);
        }

        foreach (var virtualMachineDataDisk in virtualMachine.DataDisks)
        {
            AnsiConsole.Write(new Markup(
                $"Disk name [red]{virtualMachineDataDisk.Value.StorageAccountType.Value}[/]=[red]{virtualMachineDataDisk.Value.Name}[/]"));
            AnsiConsole.WriteLine();
        }

        return virtualMachine;
    }

    public async Task StartMachineAsync(IVirtualMachine machine)
    {
        if (machine.PowerState == PowerState.Running) return;

        var vmName = machine.Name;
        AnsiConsole.WriteLine($"Machine {vmName} is not running, starting it up.");
        await AnsiConsole.Status()
            .AutoRefresh(false)
            .Spinner(Spinner.Known.Star)
            .SpinnerStyle(Style.Parse("green bold"))
            .StartAsync("Powering up Azure machine...", async ctx =>
            {
                var task = machine.StartAsync();
                var counter = 0;
                while (!task.IsCompleted)
                {
                    Thread.Sleep(1000);
                    ctx.Status = $"Powering up Azure machine {vmName} in {counter++} s tries";
                    ctx.Refresh();
                }

                ctx.Status = $"Running Azure machine {vmName} in {counter++} s";
                ctx.Refresh();
            });
    }
}