import java.awt.AWTException;
import java.awt.Dimension;
import java.awt.Image;
import java.awt.Rectangle;
import java.awt.Robot;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import javax.imageio.ImageIO;

public class ConvImage {
	/**
     * 修改一张图片的像素尺寸
     * 
     * @throws Exception
     */
	public void changeImagePixelSize(String image, String newImage, int newWidth, int newHeight) throws Exception {
		//读取图片
		BufferedInputStream in = new BufferedInputStream(new FileInputStream(image));
		//字节流转图片对象
		Image bi =ImageIO.read(in);
		//获取图像的高度，宽度
		int height=bi.getHeight(null);
		int width =bi.getWidth(null);
		//构建图片流
		BufferedImage tag = new BufferedImage(newWidth, newHeight, BufferedImage.TYPE_INT_RGB);
		//绘制改变尺寸后的图 
		tag.getGraphics().drawImage(bi, 0, 0, newWidth, newHeight, null);
		//输出流
		BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(newImage));
		//JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
		//encoder.encode(tag);
		ImageIO.write(tag, "JPG",out);
		in.close();
		out.close();
		//转字节流
		//ByteArrayOutputStream out = new ByteArrayOutputStream();

		//ImageIO.write(tag, "PNG",out);
		//InputStream is = new ByteArrayInputStream(out.toByteArray());
	}
	
	/**
     * int转为二进制符号位形式
     * 
     */
	public String intToSignedBinary(int value){
        String str = "0000000"+Integer.toBinaryString (value);
        str = str.substring(str.length()-7); // RGB 值的范围是 0-255，所以7位就足够表示
        //System.out.println(str);
		return str;
	}
	
	/**
     * 整数或整数位不为0的小数转为16位浮点数二进制形式
     * 1位符号位，5位指数位，11位基数位（实际占位10位，第一位是肯定是1，舍去不显示）
     * 
     */
	public String intToSignedFloat16(String value){
		if(value.equals("0")){
			return "0000000000000000";
		}
        StringBuffer str = new StringBuffer();
        // 判断正负
        if(value.charAt(0) == '-'){
	        str.append(1);
	        value = value.substring(1);
        }
        else
        	str.append(0);
        
        String s = String.valueOf(value);
        
        int n = s.indexOf(".");
        if(n<0){ // 如果没有小数部分，分开前在输入串的末尾补上".0"
            s += ".0";
            n = s.indexOf(".");
        }
        String s1 = s.substring(0,n);     // 整数部分
        String s2 = "0" + s.substring(n); // 小数部分
        
        String s3 = intToStr(Integer.parseInt(s1));
        String s4 = dToStr(Double.parseDouble(s2));
//        System.out.println("整数: " + s3);
//        System.out.println("小数: " + s4);
        
        s = (s3.length()==0? 0 : s3) + "." + s4; // s更新为二进制带小数点的形式
//        System.out.println("s: " + s);
        n = s3.length();
        
        int e = n-1; // 指数位的值
//        System.out.println("s3.length: " + n + "\ne: " + e);
        String eStr = intToStr(e+15);// 5位的指数位能表示的指数范围为:-15-16，所以指数部分的存储采用移位存储，存储的数据为元数据+15。
//        System.out.println("eStr: " + eStr);
        if(eStr.length() < 5){
        	for(int i = 5 - eStr.length(); i>0; i--)
        		str.append(0);
        	str.append(eStr);
        }
        else if(eStr.length() == 5)
        	str.append(eStr);
        else
        	return "Error: exponent width is bigger than 5.";
        
        // 基数位
        s3 = s3.substring(1); // 基数第一位一定是1，所以舍去不用显示
        if(s3.length() + s4.length() < 10){
        	str.append(s3);
            str.append(s4);
//            System.out.println("去掉第一位的新整数: " + s3);
//            System.out.println("小数: " + s4);
//            System.out.println("str: " + str);
        	for(int i = 10 - (s3.length() + s4.length()); i>0; i--)
        		str.append(0);
        }
        else if(s3.length() + s4.length() == 10){
        	str.append(s3);
            str.append(s4);
        }
        else
        	return "Error: fraction width is bigger than 11.";
        
		return str.toString();
	}
	
	/**
     * 把整数部分转成二进制
     * 
     */
    static String intToStr(int n){
        if(n==0) return "";
        int a = n % 2;
        int b = n / 2;
        return intToStr(b) + a;
    }
    
    /**
     * 把小数部分转成二进制
     * 
     */
    static String dToStr(double d){
        if(d-(int)d<0.01) return "" + (int)d;
        int n = (int)(d * 2);
        double a = d * 2 - n;
        return "" + n + dToStr(a);
    }
	
	/**
     * 读取一张图片的RGB值，转换存储为对应的数据格式
     * 
     * @throws Exception
     */
    public void getImagePixel(String image, String filePath) throws Exception {
        int[] rgb = new int[3];
        File file = new File(image);
        BufferedImage bi = null;
        
        try {
            bi = ImageIO.read(file);
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        try
        {
        	File binaryFile=new File(filePath);
        	if(!binaryFile.exists())
        		binaryFile.createNewFile();
        	FileOutputStream out=new FileOutputStream(binaryFile,false); //如果追加方式用true        
        	StringBuffer sb=new StringBuffer();
        	
          int width = bi.getWidth();
          int height = bi.getHeight();
          int minx = bi.getMinX();
          int miny = bi.getMinY();
          System.out.println("width=" + width + ",height=" + height + ".");
          System.out.println("minx=" + minx + ",miniy=" + miny + ".");
          for (int i = minx; i < width; i++) {
              for (int j = miny; j < height; j++) {
                  int pixel = bi.getRGB(i, j); // 下面三行代码将一个数字转换为RGB数字
                  rgb[0] = (pixel & 0xff0000) >> 16;
                  rgb[1] = (pixel & 0xff00) >> 8;
                  rgb[2] = (pixel & 0xff);
                  //sb.append(intToSignedBinary(rgb[0]) + " " + intToSignedBinary(rgb[1]) + " " + intToSignedBinary(rgb[2]) + " ");
                  sb.append(intToSignedFloat16(""+rgb[0]).substring(1) + " " 
                		  + intToSignedFloat16(""+rgb[1]).substring(1) + " " 
                		  + intToSignedFloat16(""+rgb[2]).substring(1) + " "); // 原始图片的 RGB 值都为正整数，所以第一位的0不存储，以减少图片数据大小
                  bi.setRGB(123, 123, 123);
              }
              sb.deleteCharAt(sb.length() - 1); //删除每行最后一个空格
              sb.append("\n");
          }
          out.write(sb.toString().getBytes("utf-8"));//注意需要转换对应的字符集
          out.close();
        }
        catch(IOException ex)
        {
            System.out.println(ex.getStackTrace());
        }
        
    }

    /**
     * @param args
     */
    public static void main(String[] args) throws Exception {
//        int x = 0;
        String originImage = "/Users/laimeng/Desktop/ConvImage/image_0001.jpg";
        String newImage = "/Users/laimeng/Desktop/ConvImage/image_0001_227.jpg";
        String filePath = "/Users/laimeng/Desktop/ConvImage/image_0001.mem";
        ConvImage rc = new ConvImage();
        //x = rc.getScreenPixel(100, 345);
        //System.out.println(x + " - ");
        rc.changeImagePixelSize(originImage, newImage, 227, 227);
        rc.getImagePixel(newImage, filePath);
//        System.out.println("16 bits float： " + rc.intToSignedFloat16("0"));
//        System.out.println("16 bits float： " + rc.intToSignedFloat16("-12.5"));
//        System.out.println("0:     " + Long.toBinaryString(Float.floatToRawIntBits(0)));
    }
}
