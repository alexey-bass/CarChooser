import com.adobe.serialization.json.JSON;

import flash.events.ContextMenuEvent;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.controls.Alert;
import mx.events.DataGridEvent;
import mx.events.ListEvent;
import mx.rpc.events.AbstractEvent;
import mx.rpc.events.ResultEvent;
import mx.utils.StringUtil;

[Bindable]
private var budgetsList:ArrayCollection;

[Bindable]
private var carListSource:ArrayCollection;
[Bindable]
private var carList:ArrayCollection;

[Bindable]
private var currencySign:String;
[Bindable]
public var userBudget:Number = 0;

[Bindable]
private var carsContextMenu:ContextMenu;
private var carsTableRollOverIndex:Number;

[Bindable]
private var googleImages:ArrayCollection;

protected function initApplication():void
{
	// get our cars data
	dataService.send();
	
	// populate cars table context menu
//	createContextMenu();
}

//protected function createContextMenu():void
//{
//	var menuItemGoogle:ContextMenuItem = new ContextMenuItem('Show this car in Google Search', false);
//	menuItemGoogle.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, openGoogle);
//	carsContextMenu = new ContextMenu();
//	carsContextMenu.hideBuiltInItems();
//	carsContextMenu.customItems.push(menuItemGoogle);
//}

//protected function openGoogle(event:ContextMenuEvent):void
//{
//	var row:Object = carsTable.selectedItem;
//	
//	if (row)
//		navigateToURL(new URLRequest('http://google.com/search?q=' + carList[carsTableRollOverIndex].name))
//}

protected function dataServiceHandler(event:ResultEvent):void
{
	currencySign = event.result.data.currency.sign as String;
	budgetsList = event.result.data.budgets.budget;
	
	// change app state
	// show all element before working on them!
	currentState = 'ready';
	
	// default sorting
	budgetsList.sort = new Sort();
	budgetsList.sort.fields = [new SortField('value')];
	budgetsList.refresh();
	
	carListSource = event.result.data.cars.car;
	// default sorting
	carListSource.sort = new Sort();
	carListSource.sort.fields = [new SortField('leaseFee')];
	carListSource.refresh();
	updateCarList();
}

//protected function getDiffColor(diffValue:Object):uint
//{
//	if (diffValue <= 0)
//		return 0x009900;
//	
//	return 0xff0000;
//}

protected function formatColumnMoneyValue(item:Object, column:DataGridColumn):String
{
	return moneyFormatter.format(item[column.dataField] as Number);
}

protected function labelTaxCodes(item:Object, column:DataGridColumn):String
{
	return item.manufacturer + ' - ' + item.model;
}

//protected function budgetDiffValue(data:Object):String
//{
//	if (userBudget > item.leasFee)
//		column.color = ''
	
//	return data.leaseFee;
//}

protected function changePreviewType():void
{
	if (carsTable.selectedItem)
	{
		getCarImages(carsTable.selectedItem.name);
	}
}

protected function carSelectHandler(event:ListEvent):void
{
	var query:String = event.itemRenderer.data.name;
	
	// add engine liters for better results
//	if (event.itemRenderer.data.engine)
//		query += ' ' + event.itemRenderer.data.engine + 'L';
	
	getCarImages(query);
}

/**
 * Google API help
 * http://code.google.com/apis/ajaxsearch/documentation/reference.html#_intro_fonje
 */
protected function getCarImages(query:String):void
{
	googleSearch.cancel();
	
	var params:Object = new Object;
	
	// API version
	params.v = '1.0';
	// API key for http://alexey-bass.blogspot.com/
	params.key = 'ABQIAAAAwakg1oHTtWTE4cNwaplrJhT8shxY5Q8571ux7xrw0kBQysbmaxSCHtCPbvNwvbmvO-YaCeK26tuNcg';
	
	switch (previewType.selectedItem)
	{
		case 'Video':
			googleSearch.url = 'http://ajax.googleapis.com/ajax/services/search/video';
			break;
		
		default:
			// result size, 'large' is 8 items
			params.rsz = 'large'
			// images of the specified size
			params.imgsz = 'large' // large | xlarge | xxlarge
			// images of the specified type
			params.imgtype = 'photo'
			// restrict to site
//			params.as_sitesearch = 'drive.ru'
			googleSearch.url = 'http://ajax.googleapis.com/ajax/services/search/images';
			break;
	}
	
	// query
	params.q = '"' + query + '"';
	
	previewLabel.text = 
		  'Preview for '
		+ '"' + query + '"' 
		+ ' (note that real company cars can be different from previews in some ways)';
	
	googleSearch.send(params);
}

protected function handleGoogleSearch(event:ResultEvent):void
{
	var result:Object = JSON.decode(event.result as String);
	
	if (result.responseStatus != '200')
	{
		Alert.show('Can\'t load thumbnail images.\nDetails: ' + result.responseDetails, 'Google error');
		return;
	}
	
	googleImages = new ArrayCollection(result.responseData.results);
}

protected function setUserBudget(event:ListEvent):void
{
	// enable options
	if (!filterBudget.enabled)
		filterBudget.enabled = true;
	if (!chxBudgetDiffColumn.enabled)
		chxBudgetDiffColumn.enabled = true;
	
	// save new user budget
	userBudget = event.itemRenderer.data.value as Number;
	
	// need for budget diff
	updateCarList();
}

//private function filterByBudget():void
//{
//	if (!filterBudget.selected || userBudget == 0)
//	{
//		updateCarList(carsListSource);
//		return;
//	}
//	
//	var carsFiltered:ArrayCollection = new ArrayCollection();
//	for each (var car:Object in carsListSource)
//	{
//		if (car.leaseFee as Number <= userBudget)
//			carsFiltered.addItem(car);
//	}
//	
//	updateCarList(carsFiltered);
//}

protected function updateCarList():void
{
	var newList:ArrayCollection = new ArrayCollection();
	
	// 'for each' doesnt work good with labels, see bug https://bugs.adobe.com/jira/browse/ASC-3517
	carsLoop: for (var i:Number = 0; i < carListSource.length; i++)
	{
		// virtual dynamic parameter for budget diff
		carListSource[i].budgetDiff = carListSource[i].leaseFee - userBudget;
		
		/**
		 * filter by user budget
		 */
		if (userBudget > 0 && filterBudget.selected && carListSource[i].leaseFee as Number > userBudget)
			continue carsLoop;
		
		/**
		 * car types
		 */
		var needTags:Array = new Array();
		// get tags that user wants
		var carType:String = carTagType.selectedValue.toLowerCase();
		if (carType != 'all')       needTags.push(carType);
		if (carTagHybrid.selected)  needTags.push('hybrid');
		
		// filter if need
		if (needTags.length > 0)
		{
			// tags string surrounded by spaces for search pattern
			var carTags:String = ' ' + StringUtil.trim(carListSource[i].tags) + ' ';
			// check each tag in tags string
			for (var j:Number = 0; j < needTags.length; j++)
			{
				// ex: looking for ' hybrid ' in ' sedan hybrid 5doors '
				if (carTags.indexOf(' ' + needTags[j] + ' ') == -1)
					continue carsLoop;
			}
		}
		
		// add filtered car to updated list
		newList.addItem(carListSource[i]);
	}
	
	carList = newList;
	
	if (newList.length > 1)
	{
		carsResultText.text = newList.length + ' cars are available';
	}
	else if (newList.length == 1)
	{
		carsResultText.text = '1 car is available';
	}
	else
	{
		carsResultText.text = 'No cars available';
	}
}
