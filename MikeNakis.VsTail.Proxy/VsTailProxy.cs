namespace MikeNakis.VsTail.Proxy;

using Sys = System;
using SysDebug = System.Diagnostics.Debug;
using SysDiag = System.Diagnostics;
using SysIo = System.IO;
using SysPipes = System.IO.Pipes;
using SysReflect = System.Reflection;
using SysText = System.Text;

/// <summary>
/// Connects to VsTail.
/// </summary>
// TODO: Find the executable of the server app instead of expecting it to be on a fixed path.
// TODO: explain that by using VsTail, you retain all previously enjoyed functionality, such as using VsColorOutput
//       and double-clicking on a debug output line to be taken to the source code.
// TODO: stop returning an object; instead, pass the process ID to VsTail, so that VsTail can keep track of application lifetime.
// TODO: rename the "connect" verb to "challenge" and implement a response.
public sealed class VsTailProxy
{
	const string serverAppFileName = "MikeNakis.VsTail.exe";
	const string serverPipeName = "MikeNakis.VsTail";
	static Sys.TimeSpan defaultConnectionTimeout => Sys.TimeSpan.FromMicroseconds( 5000 );

	/// <summary>
	/// Starts tailing a log file into the Debug pane of the Output window of Visual Studio.<br/>
	/// - Launches VsTail if not already running.<br/>
	/// - Passes the pathname of the currently running executable and its logfile to VsTail.<br/>
	/// - Maintains a connection so that VsTail knows when the application terminates.<br/>
	/// </summary>
	/// <returns>
	/// An object that maintains an open connection with VsTail. This object should be stored for the duration 
	/// of the application's runtime, so that VsTail knows when the application terminates.
	/// </returns>
	public static object? TryConnect( string logPathName, string solutionName, Sys.TimeSpan? connectionTimeOut = null )
	{
		if( !SysDiag.Debugger.IsAttached )
		{
			log( "Will not connect because no debugger is attached." );
			return null;
		}
		try
		{
			return connect( logPathName, solutionName, connectionTimeOut ?? defaultConnectionTimeout );
		}
		catch( Sys.Exception exception )
		{
			log( "Failed to connect", exception );
			return null;
		}

		static object? connect( string logPathName, string solutionName, Sys.TimeSpan connectionTimeOut )
		{
			try
			{
				return connectToServer( logPathName, solutionName, Sys.TimeSpan.FromSeconds( 1 ) );
			}
			catch( Sys.TimeoutException )
			{
				log( "VsTail is not running, will launch..." );
			}
			launchServerApp();
			return connectToServer( logPathName, solutionName, connectionTimeOut );

			static void launchServerApp()
			{
				string localAppDataDirectoryPath = Sys.Environment.GetFolderPath( Sys.Environment.SpecialFolder.LocalApplicationData );
				string executableDirectoryPath = SysIo.Path.Combine( localAppDataDirectoryPath, "MikeNakis.VsTail" );
				string executableFilePath = SysIo.Path.Combine( executableDirectoryPath, serverAppFileName );
				if( !SysIo.Path.Exists( executableFilePath ) )
					throw new SysIo.IOException( $"File does not exist: '{executableFilePath}'." );
				string? arguments = SysDiag.Debugger.IsAttached ? "--debug" : null;
				launchProcess( executableDirectoryPath, executableFilePath, SysDiag.ProcessWindowStyle.Minimized, arguments );
			}

			static SysPipes.NamedPipeClientStream? connectToServer( string logPathName, string solutionName, Sys.TimeSpan connectionTimeOut )
			{
				SysPipes.NamedPipeClientStream pipe = new( ".", serverPipeName, SysPipes.PipeDirection.InOut, SysPipes.PipeOptions.None );
				pipe.Connect( connectionTimeOut );
				SysIo.StreamWriter writer = new( pipe );
				writer.WriteLine( $"LogFile --file={logPathName} --solution={solutionName}" );
				writer.Flush();
				return pipe;
			}
		}
	}

	static void log( string message ) => SysDebug.WriteLine( $"{typeof( VsTailProxy ).FullName}: {message}" );

	static void log( string message, Sys.Exception exception ) => log( buildMediumExceptionMessage( message, exception ) );

	static Sys.Exception newException( string message ) => new VsTailProxyException( message );

	static Sys.Exception newException( string message, Sys.Exception innerException ) => new VsTailProxyException( message, innerException );

	static string buildMediumExceptionMessage( string prefix, Sys.Exception exception )
	{
		SysText.StringBuilder stringBuilder = new();
		while( true )
		{
			stringBuilder.Append( prefix );
			stringBuilder.Append( ": " );
			stringBuilder.Append( exception.GetType().FullName );
			stringBuilder.Append( ": " );
			stringBuilder.Append( exception.Message );
			if( exception.InnerException != null )
			{
				prefix = "; because";
				exception = exception.InnerException;
				continue;
			}
			break;
		}
		return stringBuilder.ToString();
	}

	static void launchProcess( string workingDirectoryPath, string executableFilePath, //
		SysDiag.ProcessWindowStyle windowStyle, string? arguments = null )
	{
		SysDiag.ProcessStartInfo processStartInfo = new();
		processStartInfo.FileName = executableFilePath;
		processStartInfo.WorkingDirectory = workingDirectoryPath;
		processStartInfo.WindowStyle = windowStyle;
		processStartInfo.Arguments = arguments ?? "";
		try
		{
			//PEARL: The documentation says that System.Diagnostics.Process.Start() may return `null`, but fails to
			//       explain under what circumstances this may happen. From what I gather, this may happen if you use
			//       "ShellExecute" to launch a document, and the handling process happens to already be running, so no
			//       new instance of the handling process is started.
			SysDiag.Process? process = SysDiag.Process.Start( processStartInfo ) ?? throw newException( "Process.Start() returned `null`" );
			process.WaitForInputIdle();
		}
		catch( Sys.Exception exception )
		{
			throw newException( $"Failed to launch {executableFilePath}", exception );
		}
	}
}

public sealed class VsTailProxyException : Sys.Exception
{
	/// Constructor
	public VsTailProxyException( string message )
		: base( message )
	{ }

	/// Constructor
	public VsTailProxyException( string message, Sys.Exception innerException )
			: base( message, innerException )
	{ }
}
