package components
{
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridListData;
	
	public class BudgetDiffCell extends Label
	{
		
		override public function set data(value:Object):void
		{
			if (value != null)
			{
				super.data = value;
				
				if (value[DataGridListData(listData).dataField] <= 0)
				{
					setStyle("color", 0x009900);
				}
				else
				{
					setStyle("color", 0x990000);
				}
			}
		}
	}
}
