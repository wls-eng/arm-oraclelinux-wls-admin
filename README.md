# arm-oraclelinux-wls-admin 
 Simple deployment of a Weblogic Admin Domain on Oracle Linux VM with Weblogic Server pre-installed

<table border="0">
<tr border="0">
    <td>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fwls-eng%2Farm-oraclelinux-wls-admin%2Fmaster%2Fadmindeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
    </td>
    <td>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fwls-eng%2Farm-oraclelinux-wls-admin%2Fmaster%2Fadmindeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
    </td>
  </tr>
</table>    

This template allows us to deploy Weblogic Admin Domain on Oracle Linux VM with Weblogic Server (12.2.1.3.0) pre-installed. 
This template deploy by default, an A3 size VM in the resource group location and return the fully qualified domain name of the VM.

To install Weblogic Server, requires Oracle Weblogic Install kit and Oracle JDK to be downloaded, from OTN Site (https://www.oracle.com/technical-resources/). The OTN site requires the user to accept <a href="https://www.oracle.com/downloads/licenses/standard-license.html">OTN Free Developer License Agreement</a> before downloading any resources. 
So, when this template is run, user will be required to accept the <a href="https://www.oracle.com/downloads/licenses/standard-license.html">OTN Free Developer License Agreement</a> and also provide OTN credentials (username and password), to download the Oracle Weblogic Install Kit and Oracle JDK.


<h3>Using the template</h3>

**PowerShell** 

*#use this command when you need to create a new resource group for your deployment*

*New-AzResourceGroup -Name &lt;resource-group-name&gt; -Location &lt;resource-group-location&gt; 

*New-AzResourceGroupDeployment -ResourceGroupName &lt;resource-group-name&gt; -TemplateUri https://raw.githubusercontent.com/wls-eng/arm-oraclelinux-wls-admin/master/admindeploy.json*

**Command line**

*#use this command when you need to create a new resource group for your deployment*

*az group create --name &lt;resource-group-name&gt; --location &lt;resource-group-location&gt;

*az group deployment create --resource-group &lt;resource-group-name&gt; --template-uri https://raw.githubusercontent.com/wls-eng/arm-oraclelinux-wls-admin/master/admindeploy.json*

**Post Deployment**
<p>
Follow steps once after successful deployment.
 <p> 1. Login to created VM using ssh </p>
 <p> 2. Switch to "oracle" user using sudo and then su </p>
 <p> 3. Change the directory "/u01/domains/{wlsDomainName}" </p>
 <p> 4. Start the weblogic server using startWeblogic.sh </p>
 <p> 5. Enter wlsUsername and wlsPassword credentials </p>
 <p> 6. Access the weblogic console using </p>
 <p>    http://{public ip address}:7001/console </p>
 <p>    https://{public ip address}:7002/console </p>
 <p> 7. Accessing the sample deployed application </p>
 <p>    http://{public ip address}:7001/shoppingcart </p>
 <p>    https://{public ip address}:7002/shoppingcart </p>
</p>

If you are new to Azure virtual machines, see:

- [Azure Virtual Machines](https://azure.microsoft.com/services/virtual-machines/).
- [Azure Linux Virtual Machines documentation](https://docs.microsoft.com/azure/virtual-machines/linux/)
- [Azure Windows Virtual Machines documentation](https://docs.microsoft.com/azure/virtual-machines/windows/)
- [Template reference](https://docs.microsoft.com/azure/templates/microsoft.compute/allversions)
- [Quickstart templates](https://azure.microsoft.com/resources/templates/?resourceType=Microsoft.Compute&pageNumber=1&sort=Popular)

If you are new to template deployment, see:

[Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
