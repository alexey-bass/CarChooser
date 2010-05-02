package components
{
	import mx.controls.Label;
	import mx.controls.listClasses.IListItemRenderer;
//	import spark.components.Label;
	
	public class Cell extends Label
	{
		public function Cell()
		{
			this.text = this.data.toString();
			
		}
	}
}