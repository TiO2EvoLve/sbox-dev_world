

using Sandbox;

public sealed class Portal : Component,Component.ITriggerListener
{
	[Property] public GameObject target;

	public void OnTriggerEnter(Collider other)
	{
		
		GameTags tag = other.GameObject.Tags;

		if ( tag.Has( "player" ) )
		{
			other.GameObject.Root.Transform.Position = target.Transform.Position;
		}
		
	
	}
	
	
	public void OnTriggerExit(Collider other)
	{
		
	}
}
