--Inspecting the data
select * from [dbo].[sales_port_data];

-- Checking the unique values
select distinct status from [dbo].[sales_port_data] --- Good to plot
select distinct year_id from [dbo].[sales_port_data] --- 3 Years
select distinct PRODUCTLINE from [dbo].[sales_port_data] --- 7 Products, Good to plot
select distinct COUNTRY from [dbo].[sales_port_data] --- 19 Countries, Good to plot
select distinct DEALSIZE from [dbo].[sales_port_data] --- Good to plot, Deal sizes are 3 sections, Large Medium and Small
select distinct TERRITORY from [dbo].[sales_port_data] --- 4 Territories, Good to plot


--- ANALYSIS
--- grouping sales by product
select PRODUCTLINE, SUM(sales) Revenue
from [dbo].[sales_port_data]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, SUM(sales) Revenue
from [dbo].[sales_port_data]
group by YEAR_ID
order by 2 desc

select DEALSIZE, SUM(sales) Revenue
from [dbo].[sales_port_data]
group by DEALSIZE
order by 2 desc

--- month with the best sales in the distinct years. how much was earn?
select MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequent_Orders
from [dbo].[sales_port_data]
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc --- The best month is november


--- November seems to be the best month! What is the best product sold in november
select MONTH_ID, PRODUCTLINE, SUM(sales) SalesRev ,count(ORDERNUMBER) Quantity 
from [dbo].[sales_port_data]
where YEAR_ID = 2003 and MONTH_ID = 11 --- Month has to be November
group by MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC
--- CALSSIC CARS are the best product  


---Recency=LastOrderDate, Frequency=CountOfTotalOrder, Monetary=TotalSpend
--- Who is the best customer.
DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select 
		CUSTOMERNAME,
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(select MAX(ORDERDATE) from [dbo].[sales_port_data]) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE), (select MAX(ORDERDATE) from [dbo].[sales_port_data])) Recency
	from [dbo].[sales_port_data]
	group by CUSTOMERNAME
),
rfm_calc as
(
select r.*,
	NTILE(4) OVER (order by Recency desc) rfm_recency,
	NTILE(4) OVER (order by Frequency) rfm_frequency,
	NTILE(4) OVER (order by AvgMonetaryValue) rfm_monetary
from rfm r
)
select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary   
	CASE
		when rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost customers' -- These are the lost customers.
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344) then 'customers are slipping'
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potention to be active'
		when rfm_cell_string in (323, 333, 321, 422, 332, 432) then 'active customers'
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal customers'
	END rfm_segment
from #rfm
