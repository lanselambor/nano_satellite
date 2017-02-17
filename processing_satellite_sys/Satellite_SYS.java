/**
 * @文件： Satellite_SYS
 * @说明： 小卫星软件数据文件
 *
 */
import processing.data.*;
import processing.core.*;
import processing.serial.*;
import java.io.OutputStream;

public class Satellite_SYS implements PConstants {

    // 加热板温度
    public int heating_temp = 0;
    // 卫星内部温湿度
    public float inside_temp = 0;
    public float inside_humi = 0;
    // 九轴变量
    public float rotate_x = 0;
    public float rotate_y = 0;
    public float rotate_z = 0;
    // 地磁方向
    public float compass_value = 0;
    
    // 太阳能板状态
    private int solar_panel_state;

    // 串口
    public Serial myPort;

    // 照片参数
    public long pic_length = 0;
    public float gps_LAT = 0;
    public float gps_LON = 0;
    
    // 通讯标志
    public final int COMM_SOH = 0x01;
    public final int COMM_EOT = 0x04;
    public final int COMM_ACK = 0x06;
    public final int COMM_NAK = 0x15;
    public final int COMM_CAN = 0x18;

    // 命令类型
    public final int COMM_REQUEST_SAT_DATA = 254;
    public final int COMM_OPEN_SOLAR_PANEL = 253;
    public final int COMM_CLOSE_SOLAR_PANEL = 252;
    public final int COMM_RESET_SYS = 251;
    public final int COMM_TURN_ON_HEATER = 250;
    public final int COMM_TURN_OFF_HEATER = 249;
    // public final int COMM_TAKE_PHOTO = 248;
    public final int COMM_PRE_CAPTURE = 247;
    public final int COMM_GET_PIC_LEN = 246;
    public final int COMM_RECEIVE_PIC_DATA = 245;
    public final int COMM_RESET = 244;

    PApplet papplet = new PApplet();

    public OutputStream picture;

    private long time_begin_get_sensor_data = this.papplet.millis();  // 收取传感器数据的开始时间变量

    public Satellite_SYS(){
    }

    /**
     * @函数：boolean checkData(float value, float check_data)
     * @说明：检查收到的数值正确与否 check_data = value + 1
     */
    public boolean checkData(float value, float check_data) {
      boolean ret;
      if ( 1.0 == (check_data - value) ) {
        ret = true;
      } else {
        ret = false;
      }

      return ret;
    }

    /**
     * @函数：boolean checkData(int value, int check_data)
     * @说明：检查收到的数值是否正确 check_data = value + 1
     */
    public boolean checkData(int value, int check_data) {
      boolean ret;
      if ( 1 == (check_data - value) ) {
        ret = true;
      } else {
        ret = false;
      }

      return ret;
    }  

    /**
     * @函数：int get_Sensor_data(long interval_time)
     */
    int get_Sensor_data(long interval_time) {
      // 检测串口是否初始化
      if(this.myPort == null) {
        System.out.println("mySerial not been initialized!");
        return -4;
      }

      //if (interval_time < (this.papplet.millis() - this.time_begin_get_sensor_data)) {
      //    this.time_begin_get_sensor_data = this.papplet.millis();
      //    // if (!RF_ask_for_new_task(1000)) return -1;
      //    this.myPort.clear();
      //    this.myPort.write(this.COMM_REQUEST_SAT_DATA);
      //    this.papplet.delay(500);
      //    if (RF_read_timeout(1000)) return -1;

      //    String inString = this.myPort.readStringUntil('\n');
      //    if(inString == null) {
      //      return -2;
      //    } else {
      //      System.out.println(inString);
      //      parse_sensor_data(inString);  // 开始解析传感器数据
      //      return 0;
      //    }
      //}
      
      this.myPort.clear();
      this.myPort.write(this.COMM_REQUEST_SAT_DATA);
      this.papplet.delay(800);
      if (RF_read_timeout(1000)) return -1;

      String inString = this.myPort.readStringUntil('\n');
      System.out.println(inString);      if(inString == null) {
        return -2;
      } else {
        // System.out.println(inString);
        parse_sensor_data(inString);  // 开始解析传感器数据
        return 0;
      }
      // System.out.print(this.papplet.dataPath(""));
      // return -3;
    }
    
    /**
     * @函数: public int parse_sensor_data(String inString)
     * @说明: 接收无线串口发来的信息, 解析并处理数据
     */
    public int parse_sensor_data(String inString) {

      JSONObject heat_temp = new JSONObject();
      JSONObject inside_temp = new JSONObject();
      JSONObject inside_humi = new JSONObject();
      JSONObject pos_x = new JSONObject();
      JSONObject pos_y = new JSONObject();
      JSONObject pos_z = new JSONObject();
      JSONObject heading = new JSONObject();
      JSONObject gps_latitude = new JSONObject();
      JSONObject gps_longitude = new JSONObject();
      
       try {
         JSONObject jsonData = this.papplet.parseJSONObject(inString);
         // System.out.print("JSONObject size: "); 
         // System.out.println(jsonData.size());

         if(jsonData == null) {
           System.out.println("parse error!");
         } else{
           heat_temp = jsonData.getJSONObject("HEAT_TMP");
           inside_temp = jsonData.getJSONObject("IN_TMP");
           inside_humi = jsonData.getJSONObject("IN_HUMI");
           pos_x = jsonData.getJSONObject("POS_X");
           pos_y = jsonData.getJSONObject("POS_Y");
           pos_z = jsonData.getJSONObject("POS_Z");
           heading = jsonData.getJSONObject("HEAD");
           gps_latitude = jsonData.getJSONObject("GPS_LAT");
           gps_longitude = jsonData.getJSONObject("GPS_LON");
           
           try {
             if(checkData(heat_temp.getInt("value"), heat_temp.getInt("check"))) {
               // System.out.print("heat_temp: ");
               // System.out.println(heat_temp.getInt("value"));
               this.heating_temp = heat_temp.getInt("value");

             }
           } catch (Exception e) {} 

           try {
             if(checkData(inside_temp.getFloat("value"), inside_temp.getFloat("check"))) {
               // System.out.print("inside_temp: ");
               // System.out.println(inside_temp.getFloat("value"));
               this.inside_temp = inside_temp.getFloat("value");

             }
           } catch (Exception e) {} 
           try {  
             if(checkData(inside_humi.getFloat("value"), inside_humi.getFloat("check"))) {
               // System.out.print("inside_humi:");
               // System.out.println(inside_humi.getFloat("value"));
               this.inside_humi = inside_humi.getFloat("value");
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(pos_x.getFloat("value"), pos_x.getFloat("check"))) {
               float p_x = pos_x.getFloat("value");
               if( p_x < -1.0 ) {
                 p_x = (float)-1.0;
               } else if(p_x > 1.0){
                 p_x = (float)1.0;
               }
               // System.out.print("pos_x: ");
               // System.out.println(p_x);
               this.rotate_x = p_x;
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(pos_y.getFloat("value"), pos_y.getFloat("check"))) {
               float p_y = pos_y.getFloat("value");
               if( p_y < -1.0){
                 p_y = (float)-1.0;
               } else if (p_y > 1.0){
                 p_y = (float)1.0;
               }
               // System.out.print("pos_y: ");
               // System.out.println(p_y);
               this.rotate_y = p_y;
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(pos_z.getFloat("value"), pos_z.getFloat("check"))) {
               float p_z = pos_z.getFloat("value");
               if( p_z < -1.0 ){
                 p_z = (float)-1.0;
               } else if(p_z > 1.0){
                 p_z = (float)1.0;
               }
               // System.out.print("pos_z: ");
               // System.out.println(p_z);
               this.rotate_z = p_z;
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(heading.getFloat("value"), heading.getFloat("check"))) {
               // System.out.print("heading: ");
               // System.out.println(heading.getFloat("value"));
               this.compass_value = heading.getFloat("value");
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(gps_latitude.getFloat("value"), gps_latitude.getFloat("check"))) {
               // System.out.print("gps_latitude: ");
               // System.out.println(gps_latitude.getFloat("value"));
               float dd = gps_latitude.getFloat("value") % 100 / 60;
               this.gps_LAT = gps_latitude.getFloat("value") / 100 + dd;
             }
           } catch (Exception e) {} 

           try {  
             if(checkData(gps_longitude.getFloat("value"), gps_longitude.getFloat("check"))) {
               // System.out.print("gps_longitude: ");
               // System.out.println(gps_longitude.getFloat("value"));
               float dd = gps_longitude.getFloat("value") % 100 / 60;
               this.gps_LON = gps_longitude.getFloat("value") / 100 + dd;
             }
           } catch (Exception e) {} 


           // System.out.println("");
         }
       } catch (Exception e) {
         //e.printStackTrace();
       }
       
       return 0;
    }

    /**
     * @函数：public int RF_serial_test()
     */
    public int RF_serial_test() {
        int data = -1;

        this.myPort.clear();
        this.myPort.write(this.COMM_RESET);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) {
          return -1;
        }
        while(this.myPort.available() > 0) {
          data = this.myPort.read();
          System.out.println(data); 
        }
        //System.out.println("Received data: " + data); 
        if (data != this.COMM_RESET) {
          return -2;
        }
        //this.myPort.clear();
        
        return 0;
    }

    /**
     * @函数：public void open_solar_panel()
     */
    public int open_solar_panel() {
        System.out.println("Opening solar panel!");
        this.myPort.clear();
        this.myPort.write(this.COMM_OPEN_SOLAR_PANEL);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) return -1;

        int data = this.myPort.read();
        System.out.println("Received data bakc: " + data);
        if(data == this.COMM_OPEN_SOLAR_PANEL) {
          this.solar_panel_state = 0;
          System.out.println("Opened solar panel!");
        } 
        return 0;
    }

    /**
     * @函数：public void close_solar_panel()
     */
    public int close_solar_panel() {
        System.out.println("Colsing solar panel!");
        this.myPort.clear();
        this.myPort.write(this.COMM_CLOSE_SOLAR_PANEL);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) return -1;

        int data = this.myPort.read();
        System.out.println("Received data back: " + data);
        if(data == this.COMM_CLOSE_SOLAR_PANEL) {
          solar_panel_state = 0;
          System.out.println("Colsed solar panel!");
        }

        return 0;
    }

    /**
     * @函数：public void open_heater()
     */
    public int open_heater() {
        System.out.println("Opening heater!");
        this.myPort.clear();
        this.myPort.write(this.COMM_TURN_ON_HEATER);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) return -1;

        int data = this.myPort.read();
        System.out.println("Received data back: " + data);
        if(data == this.COMM_TURN_ON_HEATER) {
          this.solar_panel_state = 0;
          System.out.println("Open heater succeed!");
        } 
        return 0;
    }

    /**
     * @函数：public void close_heater()
     */
    public int close_heater() {
        System.out.println("Closing heater!");
        this.myPort.clear();
        this.myPort.write(this.COMM_TURN_OFF_HEATER);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) return -1;

        int data = this.myPort.read();
        System.out.println("Received data back: " + data);
        if(data == this.COMM_TURN_OFF_HEATER) {
          solar_panel_state = 0;
          System.out.println("Colse heater succeed!");
        }

        return 0;
    }


    /**
      *@函数：public int take_photo_precapture()
     */
    public int take_photo_precapture(){
      System.out.println("Pre-capturing!");
      this.myPort.clear();
      this.myPort.write(this.COMM_PRE_CAPTURE);
      this.papplet.delay(100);
      if (RF_read_timeout(1000)) return -1;

      int data = this.myPort.read();
      System.out.println("Received data back: " + data);
      if(data == this.COMM_PRE_CAPTURE) {
        System.out.println("Pre-capture done!");
      } else{
        System.out.println("Pre-capture failed...!");
        return -2;
      }

      return 0;
    }

    /**
      *@函数：public int get_pic_len()
     */
    public int get_pic_len() {
      long len = 0;

      System.out.println("Get pic length!");
      this.myPort.clear();
      // while(0 < this.myPort.available()) {  // 清除串口缓存
      //    this.myPort.read();
      //  }
      this.myPort.write(this.COMM_GET_PIC_LEN);
      this.papplet.delay(500);
      if (RF_read_timeout(1000)) return -1;

      String data = this.myPort.readStringUntil('\n');
      data = data.trim();
      System.out.println("Get pic length: " + data);
      try{
        len = Long.parseLong(data, 10);
      }catch (Exception e){
        e.printStackTrace();
        return -2;
      }
      if ((1000 < len) && (len < 40000)) {
        this.pic_length = len;
      } else {
        this.pic_length = 0;
        return -3;
      }

      return 0;
    }

    /**
      *@函数：public int receive_pic_data()
     */
    public int receive_pic_data() {
      try {
        System.out.println("Receiving pic!");
        final int dataSize = 1023;
        this.picture = this.papplet.createOutput("pic.jpg");
        this.myPort.clear();
        this.myPort.write(this.COMM_RECEIVE_PIC_DATA);
        this.papplet.delay(100);
        if (RF_read_timeout(1000)) {
          this.picture.close();
          return -1;
        }

        int data = this.myPort.read();
        System.out.println("Received data back: " + data);
        
        
        if (data == this.COMM_RECEIVE_PIC_DATA) {
          // Start receive pic data
          long data_len_received = 0;
          int error_counter = 0;
          while( this.pic_length > data_len_received ) {

            int[] dataBuffer = new int[dataSize];
            int checksum = 0;
            int sum = 0;

            this.papplet.delay(200);
            
            // 1.读取 dataSize Bytes
            //while(this.myPort.available() < 128);
            for(int i = 0; i < dataSize; i++){
              if(RF_read_timeout(1000)){

                System.out.println("Read dataSize bytes timeout!");

                // 错误次数过多，退出
                if(5 <= ( error_counter++ )) {
                  this.myPort.write(COMM_CAN);
                  this.picture.close();
                  return -1;
                }
                // 超时重发
                this.myPort.write(COMM_NAK);
                continue;
              }
              dataBuffer[i] = this.myPort.read();
              sum += dataBuffer[i];
              sum = sum % 0xFF;
            }
            // 错误次数清零
            error_counter = 0;
            

            // 2.等待校验和到来
            if (RF_read_timeout(1000)) { // 等待校验和
              //this.picture.close();
              System.out.println("Waiting for checksum timeout!");
              this.myPort.write(COMM_NAK);
              continue;
              //return -1;
            }

            // 3.读取校验和
            checksum = this.myPort.read();  // 读取校验和

            // 4.检查校验和, 数据写入图片文件
            if(sum != checksum) {  // 判断校验和
              this.myPort.clear();  // 清除串口缓存
              this.myPort.write(this.COMM_NAK); // 校验和不对，发送重发命令 - ‘0’
              System.out.println("Checksum error!");
              continue;
            } else{
              if (data_len_received <= this.pic_length) {
                for (int i = 0; i < dataSize; i++) {
                  picture.write(dataBuffer[i]);  // 写入 dataSize 字节数据
                }
              } else {
                for (int i = 0; i < (this.pic_length + dataSize - data_len_received); i++) {
                  picture.write(dataBuffer[i]);  // 写入最后不到dataSize字节的数据
                }
                break;
              }
              this.myPort.write(this.COMM_ACK);
            }
              
            data_len_received += dataSize;
            System.out.println("data_received: " + data_len_received*100/this.pic_length + "%");
          }
        } else {
          this.picture.close();
          return -2;
        }

        //this.picture.close();
      } catch (Exception e) {
        //this.picture.close();
        e.printStackTrace();
      }
      return 0;
    }

    /**
     * @函数：boolean RF_ask_for_new_task(long timeout)
     */
    boolean RF_ask_for_new_task(long timeout) {
        boolean is_receive_ack = false;

        // if (this.myPort.available() > 1) this.myPort.clear();  // 清除Seiral缓存
        // this.myPort.write(COMM_FAKE);  // 发送一个伪字节，
        this.myPort.write(this.COMM_SOH);
        is_receive_ack = RF_wait_for_ack(timeout);

        return is_receive_ack;
    }

    /**
     * @函数：boolean RF_wait_for_ack(long timeout)
     */
    boolean RF_wait_for_ack(long timeout) {
        int data;
        boolean ret;

        ret = RF_read_timeout(timeout);

        if(!ret) {
            data = this.myPort.read();
            // System.out.print("RF_wait_for_ack: ");
            // System.out.println(data);
            if(this.COMM_ACK == data) {
              return true;
            }
        }

        return false;
    }

    /**
     * @函数：boolean RF_read_timeout(long timeout)
     * @参数：timeout: 毫秒
     * @说明：等待串口数据，超时返回
     */
    boolean RF_read_timeout(long timeout) {
        boolean state = false;
        int available_data_num = 0;
        long time_start = this.papplet.millis();

        while(available_data_num <= 0) {
          this.papplet.delay(5);
          available_data_num = this.myPort.available();
          //System.out.println("RF_read_timeout available number: " + available_data_num);
          if(timeout < this.papplet.millis() - time_start) {
            state = true;
            // System.out.println("RF_read_timeout out: " + this.myPort.available());
            break;
          }
        }

        return state;
    }


}