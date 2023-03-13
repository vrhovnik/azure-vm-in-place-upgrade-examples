namespace UpdateViaManagedAPI;

public class AzureException : Exception
{
    public AzureException(string error) : base(error)
    {
    }

}